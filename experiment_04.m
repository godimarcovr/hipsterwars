if ~exist('features')
    load styleDescriptor.mat
    load hipsterwars_Jan_2014.mat
    load posePoints.mat
    load scaleValue.mat
end

train_perc = 0.9;
delta = 0.2;
n_parts = 24;
n_items = 56;
patch_halfdim = 16;
names = {'Hipster', 'Goth', 'Preppy', 'Pinup', 'Bohemian'};
seg_src_path = ('hipsterwars_segmentation_results/');
vis_dst_path = 'hipsterwars_computed_testingset/';
item_labels = {'null', 'tights', 'shorts', 'blazer', 't-shirt', 'bag', 'shoes', 'coat', 'skirt', 'purse', 'boots', 'blouse', 'jacket', 'bra', 'dress', 'pants', 'sweater', 'shirt', 'jeans', 'leggings', 'scarf', 'hat', 'top', 'cardigan', 'accessories', 'vest', 'sunglasses', 'belt', 'socks', 'glasses', 'intimate', 'stockings', 'necklace', 'cape', 'jumper', 'sweatshirt', 'suit', 'bracelet', 'heels', 'wedges', 'ring', 'flats', 'tie', 'romper', 'sandals', 'earrings', 'gloves', 'sneakers', 'clogs', 'watch', 'pumps', 'wallet', 'bodysuit', 'loafers', 'hair', 'skin'};
paper_labels = [6, 28, 4, 12, 11, 24, 8, 15, 55, 39, 13, 19, 20, 16, 18, 7, 3, 56, 9, 17, 2, 23];

part_features_len = size(features, 2) / n_parts;
sets = cell(length(names), 1);
train_features = zeros(0, size(features, 2));
%% split
for i=1:length(names)
    ind_list = get_indexes_by_style( samples, names{i} );
    coord_ind_list = [];
    for j=ind_list
        coord_ind_list = [coord_ind_list (2*j)-1 2*j];
    end
    style_features = features(ind_list, :);
    style_samples = samples(ind_list);
    style_scales = scaleVal(ind_list, :);
    style_coordinates = coordinates(coord_ind_list, :);
    
    [top_ind_list, ~] = get_indexes_by_top_perc( style_samples, delta );
    [~, bottom_ind_list] = get_indexes_by_top_perc( style_samples, 1.0 - delta );
    style_samples = [style_samples(top_ind_list); style_samples(bottom_ind_list)];
    style_features = [style_features(top_ind_list, :); style_features(bottom_ind_list, :)];
    style_scales = [style_scales(top_ind_list, :); style_scales(bottom_ind_list, :)];
    coord_ind_list = [];
    for j=[top_ind_list bottom_ind_list]
        coord_ind_list = [coord_ind_list (2*j)-1 2*j];
    end
    style_coordinates = style_coordinates(coord_ind_list, :);
    
    labels = zeros(numel(top_ind_list) + numel(bottom_ind_list), 1);
    labels(1:numel(top_ind_list)) = 1; %positivi
    labels(numel(top_ind_list) + 1:end) = 2; %negativi
    
    ntot = numel(top_ind_list) + numel(bottom_ind_list);
    perm = randperm(ntot);
    
    style_test_inds = perm(ceil(train_perc * ntot) + 1:end);
    coord_test_inds = [];
    for j=style_test_inds
        coord_test_inds = [coord_test_inds (2*j)-1 2*j];
    end
    style_test_labels = labels(style_test_inds);
    style_test_samples = style_samples(style_test_inds, :);
    style_test_features = style_features(style_test_inds, :);
    style_test_scales = style_scales(style_test_inds, :);
    style_test_coordinates = style_coordinates(coord_test_inds, :);
    
    style_train_inds = perm(1:ceil(train_perc * ntot));
    coord_train_inds = [];
    for j=style_train_inds
        coord_train_inds = [coord_train_inds (2*j)-1 2*j];
    end
    style_train_labels = labels(style_train_inds);
    style_train_samples = style_samples(style_train_inds, :);
    style_train_features = style_features(style_train_inds, :);
    style_train_scales = style_scales(style_train_inds, :);
    style_train_coordinates = style_coordinates(coord_train_inds, :);
    
    sets{i}.train.labels = style_train_labels;
    sets{i}.train.samples = style_train_samples;
    sets{i}.train.features = style_train_features;
    sets{i}.train.scales = style_train_scales;
    sets{i}.train.coordinates = style_train_coordinates;

    sets{i}.test.labels = style_test_labels;
    sets{i}.test.samples = style_test_samples;
    sets{i}.test.features = style_test_features;
    sets{i}.test.scales = style_test_scales;
    sets{i}.test.coordinates = style_test_coordinates;
    
    train_features = [train_features; style_train_features];
end

%% train models
[ normalized_train_features, train_feature_avgs, train_feature_stds ] = normalize_features_fn( train_features );
models = cell(length(names), 1);
for i=1:length(names)
    names{i}
    [normalized_style_train_features, ~, ~] = normalize_features_fn(sets{i}.train.features, train_feature_avgs, train_feature_stds);
    C = train(sets{i}.train.labels, sparse(normalized_style_train_features), '-s 0 -C -v 5 -q');
    models{i} = train(sets{i}.train.labels, sparse(normalized_style_train_features), ['-s 0 -c ', num2str(C(1)), ' -q']);
end

%% compute part scores
part_scores_by_style = cell(length(names), 1);

for style_i=1:length(names)
    part_scores_by_style{style_i} = zeros(size(sets{style_i}.test.features, 1), n_parts);
    for sample_i=1:size(sets{style_i}.test.features, 1)
        p = zeros(n_parts, 1);
        tmp_features = sets{style_i}.test.features(sample_i, :);
        [tmp_features_normalized, ~, ~] = normalize_features_fn(tmp_features, train_feature_avgs, train_feature_stds);
        for i=1:n_parts
            tmp_features_normalized_part = tmp_features_normalized(1 + part_features_len * (i-1):part_features_len * i);
            tmp_pred = - models{style_i}.w(1 + part_features_len * (i-1):part_features_len * i) * tmp_features_normalized_part';
            p(i) = 1 / (1 + exp(tmp_pred));
        end
        part_scores_by_style{style_i}(sample_i, :) = p(:);
    end
end

%% create images
for style_i=1:length(names)
    names{style_i}
    sets{style_i}.test.part_scores_maps = cell(size(sets{style_i}.test.features, 1), 1);
    sets{style_i}.test.item_scores_maps = cell(size(sets{style_i}.test.features, 1), 1);
    sets{style_i}.test.item_scores = cell(size(sets{style_i}.test.features, 1), 1);
    sets{style_i}.test.seg_img = cell(size(sets{style_i}.test.features, 1), 1);
    for sample_i=1:size(sets{style_i}.test.features, 1)
        sample_i
        sample_id = sets{style_i}.test.samples(sample_i).id;
        seg_file_path = [seg_src_path num2str(sample_id) '.png'];
        seg_img = imread(seg_file_path);
        seg_img = seg_img(:, :, 1);
        seg_img = seg_img + 1; %[0;55] -> [1;56]
        sets{style_i}.test.seg_img{sample_i} = seg_img;
        
        x_patch_halfdim = sets{style_i}.test.scales(sample_i, 1) * patch_halfdim;
        y_patch_halfdim = sets{style_i}.test.scales(sample_i, 2) * patch_halfdim;
        
        tmp_patch_acc = NaN([size(seg_img) n_parts]);
        for i=1:n_parts
            tmpp = part_scores_by_style{style_i}(sample_i, i);
            tmp_center = sets{style_i}.test.coordinates([(2*sample_i)-1 2*sample_i], i);
            
            y_a = max(round(tmp_center(2)-y_patch_halfdim), 1);
            x_a = max(round(tmp_center(1)-x_patch_halfdim), 1);
            y_b = min(round(tmp_center(2)+y_patch_halfdim-1), size(seg_img, 1));
            x_b = min(round(tmp_center(1)+x_patch_halfdim-1), size(seg_img, 2));
            
            tmp_patch_acc(y_a:y_b,x_a:x_b,i) = tmpp;
        end


        part_scores_map = nanmean(tmp_patch_acc, 3);
        part_scores_map(isnan(part_scores_map)) = 0.5;
%         part_scores_map = ones(size(seg_img)).*0.5;
%         for r=1:size(seg_img, 1)
%             for c=1:size(seg_img, 2)
%                 tmp_scores_acc = tmp_patch_acc(r, c, tmp_patch_acc(r, c, :) ~= 0);
%                 if numel(tmp_scores_acc) ~= 0
%                     part_scores_map(r, c) = mean(tmp_scores_acc);
%                 end
%             end
%         end
        sets{style_i}.test.part_scores_maps{sample_i} = part_scores_map;
        
        item_scores_map = ones(size(seg_img)).*0.5;
        item_scores = zeros(n_items,1);
        for i=1:n_items
            item_i_pixels = seg_img == i;
            item_scores_map(item_i_pixels) = mean(part_scores_map(item_i_pixels));
            if max(max(item_i_pixels)) ~= 0
                item_scores(i) = mean(part_scores_map(item_i_pixels));
            end
        end
        sets{style_i}.test.item_scores_maps{sample_i} = item_scores_map;
        sets{style_i}.test.item_scores{sample_i} = item_scores;
    end
end

for style_i=1:length(names) 
    names{style_i}
    for sample_i=1:size(sets{style_i}.test.features, 1)
        sample_i
        f = figure;
        if sets{style_i}.test.labels(sample_i) == 1
            posneg = 'Positive sample';
        else
            posneg = 'Negative sample';
        end
        set(f, 'Visible', 'off');
        subplot(1,3,1);
        imshow(sets{style_i}.test.samples(sample_i).image)
        hold on
        plot(sets{style_i}.test.coordinates([(2*sample_i)-1], :), sets{style_i}.test.coordinates([2*sample_i], :), 'rx');
        hold off
        subplot(1,3,2);
        imagesc(sets{style_i}.test.item_scores_maps{sample_i})
        title([names{style_i} ' ' posneg])
        colorbar
        subplot(1,3,3);
        imagesc(sets{style_i}.test.part_scores_maps{sample_i})
        colorbar
        f.PaperUnits = 'inches';
        f.PaperPosition = [0 0 16 8];
        print([vis_dst_path num2str(sets{style_i}.test.samples(sample_i).id)],'-dpng','-r0')
        delete(f)
        clear f
    end
end

train_pixelcount_features = zeros(0, n_items);

for style_i=1:length(names)
    sets{style_i}.train.pixelcounts_by_item = zeros(size(sets{style_i}.train.features, 1), n_items);
    for sample_i=1:size(sets{style_i}.train.features, 1)
        imgname = sets{style_i}.train.samples(sample_i).id;

        img = imread([seg_src_path num2str(imgname) '.png']);
        img = img(:, :, 1) + 1;
        % Normalizza maybe?
        present_labels = unique(img);
        label_n_pixels = [];
        for label=present_labels'
            label_n_pixels = [label_n_pixels length(img(img == label))];
        end
        
        tmp_counts = zeros(1, n_items);
        tmp_counts(present_labels) = log(label_n_pixels);
        sets{style_i}.train.pixelcounts_by_item(sample_i, :) = tmp_counts;
    end
    train_pixelcount_features = [train_pixelcount_features; sets{style_i}.train.pixelcounts_by_item];
end

[ normalized_train_pixelcount_features, train_pixelcount_feature_avgs, train_pixelcount_feature_stds ] = normalize_features_fn( train_pixelcount_features );

pixelcount_models = cell(length(names), 1);
for i=1:length(names)
    names{i}
    [normalized_style_train_pixelcount_features, ~, ~] = normalize_features_fn(sets{i}.train.pixelcounts_by_item, train_pixelcount_feature_avgs, train_pixelcount_feature_stds);
    C = train(sets{i}.train.labels, sparse(normalized_style_train_pixelcount_features), '-s 0 -C -v 5 -q');
    pixelcount_models{i} = train(sets{i}.train.labels, sparse(normalized_style_train_pixelcount_features), ['-s 0 -c ', num2str(C(1)), ' -q']);
end
