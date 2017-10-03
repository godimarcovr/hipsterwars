% if ~exist('features')
%     load styleDescriptor.mat
%     load hipsterwars_Jan_2014.mat
%     load posePoints.mat
% end
% 
% train_perc = 0.9;
% delta = 0.2;
% n_parts = 24;
% n_items = 56;
% patch_halfdim = 16;
% names = {'Hipster', 'Goth', 'Preppy', 'Pinup', 'Bohemian'};
% seg_src_path = ('hipsterwars_segmentation_results/');
% 
% part_features_len = size(features, 2) / n_parts;
% sets = cell(length(names), 1);
% train_features = zeros(0, size(features, 2));
% for i=1:length(names)
%     ind_list = get_indexes_by_style( samples, names{i} );
%     style_features = features(ind_list, :);
%     style_samples = samples(ind_list);
%     
%     [top_ind_list, ~] = get_indexes_by_top_perc( style_samples, delta );
%     [~, bottom_ind_list] = get_indexes_by_top_perc( style_samples, 1.0 - delta );
%     style_samples = [style_samples(top_ind_list); style_samples(bottom_ind_list)];
%     style_features = [style_features(top_ind_list, :); style_features(bottom_ind_list, :)];
%     coord_ind_list = [];
%     for j=[top_ind_list bottom_ind_list]
%         coord_ind_list = [coord_ind_list (2*j)-1 2*j];
%     end
%     style_coordinates = coordinates(coord_ind_list, :);
%     
%     labels = zeros(numel(top_ind_list) + numel(bottom_ind_list), 1);
%     labels(1:numel(top_ind_list)) = 1; %positivi
%     labels(numel(top_ind_list) + 1:end) = 2; %negativi
%     
%     ntot = numel(top_ind_list) + numel(bottom_ind_list);
%     perm = randperm(ntot);
%     
%     style_test_inds = perm(ceil(train_perc * ntot) + 1:end);
%     coord_test_inds = [];
%     for j=style_test_inds
%         coord_test_inds = [coord_test_inds (2*j)-1 2*j];
%     end
%     style_test_labels = labels(style_test_inds);
%     style_test_samples = style_samples(style_test_inds, :);
%     style_test_features = style_features(style_test_inds, :);
%     style_test_coordinates = style_coordinates(coord_test_inds, :);
%     
%     style_train_inds = perm(1:ceil(train_perc * ntot));
%     coord_train_inds = [];
%     for j=style_train_inds
%         coord_train_inds = [coord_train_inds (2*j)-1 2*j];
%     end
%     style_train_labels = labels(style_train_inds);
%     style_train_samples = style_samples(style_train_inds, :);
%     style_train_features = style_features(style_train_inds, :);
%     style_train_coordinates = style_coordinates(coord_train_inds, :);
%     
%     sets{i}.train.labels = style_train_labels;
%     sets{i}.train.samples = style_train_samples;
%     sets{i}.train.features = style_train_features;
%     sets{i}.train.coordinates = style_train_coordinates;
% 
%     sets{i}.test.labels = style_test_labels;
%     sets{i}.test.samples = style_test_samples;
%     sets{i}.test.features = style_test_features;
%     sets{i}.test.coordinates = style_test_coordinates;
%     
%     train_features = [train_features; style_train_features];
% end
% 
% [ normalized_train_features, train_feature_avgs, train_feature_stds ] = normalize_features_fn( train_features );
% models = cell(length(names), 1);
% for i=1:length(names)
%     names{i}
%     [normalized_style_train_features, ~, ~] = normalize_features_fn(sets{i}.train.features, train_feature_avgs, train_feature_stds);
%     C = train(sets{i}.train.labels, sparse(normalized_style_train_features), '-s 0 -C -v 5 -q');
%     models{i} = train(sets{i}.train.labels, sparse(normalized_style_train_features), ['-s 0 -c ', num2str(C(1)), ' -q']);
% end
% 
% part_scores_by_style = cell(length(names), 1);
% 
% for style_i=1:length(names)
%     part_scores_by_style{style_i} = zeros(size(sets{style_i}.test.features, 1), n_parts);
%     for sample_i=1:size(sets{style_i}.test.features, 1)
%         p = zeros(n_parts, 1);
%         tmp_features = sets{style_i}.test.features(sample_i, :);
%         [tmp_features_normalized, ~, ~] = normalize_features_fn(tmp_features, train_feature_avgs, train_feature_stds);
%         for i=1:n_parts
%             tmp_features_normalized_part = tmp_features_normalized(1 + part_features_len * (i-1):part_features_len * i);
%             tmp_pred = - models{style_i}.w(1 + part_features_len * (i-1):part_features_len * i) * tmp_features_normalized_part';
%             p(i) = 1 / (1 + exp(tmp_pred));
%         end
%         part_scores_by_style{style_i}(sample_i, :) = p(:);
%     end
% end
% 
% for style_i=1:length(names) 
%     sets{style_i}.test.part_scores_maps = cell(size(sets{style_i}.test.features, 1), 1);
%     sets{style_i}.test.item_scores_maps = cell(size(sets{style_i}.test.features, 1), 1);
%     sets{style_i}.test.item_scores = cell(size(sets{style_i}.test.features, 1), 1);
%     for sample_i=1:size(sets{style_i}.test.features, 1)
%         sample_id = sets{style_i}.test.samples(sample_i).id;
%         seg_file_path = [seg_src_path num2str(sample_id) '.png'];
%         seg_img = imread(seg_file_path);
%         seg_img = seg_img(:, :, 1);
%         
%         tmp_patch_acc = zeros([size(seg_img) n_parts]);
%         for i=1:n_parts
%             tmpp = part_scores_by_style{style_i}(sample_i, i);
%             tmp_center = round(sets{style_i}.test.coordinates([(2*sample_i)-1 2*sample_i], i));
%             tmp_patch_acc(tmp_center(2)-patch_halfdim:tmp_center(2)+patch_halfdim-1,tmp_center(1)-patch_halfdim:tmp_center(1)+patch_halfdim-1,i) = tmpp;
%         end
% 
%         part_scores_map = ones(size(seg_img)).*0.5;
%         for r=1:size(seg_img, 1)
%             for c=1:size(seg_img, 2)
%                 tmp_scores_acc = tmp_patch_acc(r, c, tmp_patch_acc(r, c, :) ~= 0);
%                 if numel(tmp_scores_acc) ~= 0
%                     part_scores_map(r, c) = mean(tmp_scores_acc);
%                 end
%             end
%         end
%         sets{style_i}.test.part_scores_maps{sample_i} = part_scores_map;
%         
%         item_scores_map = ones(size(seg_img)).*0.5;
%         item_scores = zeros(n_items,1);
%         for i=1:n_items
%             item_i_pixels = seg_img == i;
%             item_scores_map(item_i_pixels) = mean(part_scores_map(item_i_pixels));
%             if max(max(item_i_pixels)) ~= 0
%                 item_scores(i) = mean(part_scores_map(item_i_pixels));
%             end
%         end
%         sets{style_i}.test.item_scores_maps{sample_i} = item_scores_map;
%         sets{style_i}.test.item_scores{sample_i} = item_scores;
%     end
% end

for style_i=1:length(names) 
    for sample_i=1:size(sets{style_i}.test.features, 1)
        f = figure;
        set(h, 'Visible', 'off');
        subplot(
    end
end

