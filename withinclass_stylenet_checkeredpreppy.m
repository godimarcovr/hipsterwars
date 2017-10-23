% if ~exist('features')
%     %load features_stylenet.mat
%     load sets_p.mat
%     features = hdf5read('features_preppycheckered.h5', '/features');
%     features = double(features');
%     sets_p{3}.train.features = features;
%     sets_p{3}.test = sets_p{3}.train;
% end
% 
% train_perc = 0.9;
% delta = 0.2;
% names = {'Preppy'};
% 
% sets = sets_p(3);
% 
% %% train models
% models = cell(length(names), 1);
% for i=1:length(names)
%     names{i}
%     % [normalized_style_train_features, ~, ~] = normalize_features_fn(sets{i}.train.features, train_feature_avgs, train_feature_stds);
%     C = train(sets{i}.train.labels, sparse(sets{i}.train.features), '-s 0 -C -v 5');
%     models{i} = train(sets{i}.train.labels(3:end), sparse(sets{i}.train.features(3:end, :)), ['-s 0 -c ', num2str(C(1)), '']);
% end
% 
% %%
% covered_list = [];
% covered_stylesample_inds = [];
% number_of_samples = -1; %n or -1
% for style_i=1:length(names)
%     tmp_testset = sets{style_i}.test.samples;
%     tmp_labels = sets{style_i}.test.labels;
%     checkered_inds = find(tmp_labels == 1)';
%     non_checkered_inds = find(tmp_labels == 2)';
% %     covered_list = [covered_list; tmp_testset(1).id; tmp_testset(end).id];
% %     covered_list = [covered_list; tmp_testset(1).id; tmp_testset(2).id; tmp_testset(end - 1).id; tmp_testset(end).id];
%     if number_of_samples < 0
%         covered_list = [covered_list; [tmp_testset(:).id]'];
%         covered_stylesample_inds = [covered_stylesample_inds; [ones(size(tmp_labels,1), 1).*style_i [1:size(tmp_testset, 1)]' tmp_labels]];
%     else
%         for i=checkered_inds(1:number_of_samples)
%             covered_list = [covered_list; tmp_testset(i).id];
%         end
%         for i=non_checkered_inds(1:number_of_samples)
%             covered_list = [covered_list; tmp_testset(i).id];
%         end
%         for i=checkered_inds(1:number_of_samples)
%             covered_stylesample_inds = [covered_stylesample_inds; style_i i tmp_labels(i)];
%         end
%         for i=non_checkered_inds(1:number_of_samples)
%             covered_stylesample_inds = [covered_stylesample_inds; style_i i tmp_labels(i)];
%         end
%     end
% %     covered_stylesample_inds = [covered_stylesample_inds; style_i index(end) tmp_labels(end); style_i index(1) tmp_labels(1)];
% %     covered_stylesample_inds = [covered_stylesample_inds; style_i index(end) tmp_labels(end); style_i index(end-1) tmp_labels(end-1); style_i index(2) tmp_labels(2); style_i index(1) tmp_labels(1)];
% end
% 
% %%
% features = hdf5read('features_preppycheckered_covered.h5', '/features');
% features = squeeze(features);
% features = double(features');
% info = hdf5read('features_preppycheckered_covered.h5', '/info');
% info = info';
% patch_features = cell(size(info, 1), 1);
% for i=1:size(info, 1)
%     patch_features{i}.features = features(i, :);
%     patch_features{i}.coord = info(i, 2:3);
%     patch_features{i}.id = num2str(info(i, 1));
% end
% 
% %%
% counters = zeros(size(patch_features, 1), 1);
% for i=1:size(patch_features, 1)
%     counters(i) = str2double(patch_features{i}.id);
% end
% unique(counters)
% % sum(counters == 16683)


%% 3 pos funziona, 4 e 5 pos non funziona, 6 pos funziona
patch_dim = 48;
step = 12;
for stylesample_i=1:size(covered_stylesample_inds, 1)
    stylesample_i
%     style_tested = 2;
%     image_tested = 6;
    style_tested = covered_stylesample_inds(stylesample_i, 1);
    %if negative class has positive scores
    if models{style_tested}.Label(1) == 2
        scoreinv_mult = -1;
    else
        scoreinv_mult = 1;
    end
    image_tested = covered_stylesample_inds(stylesample_i, 2);
    label_tested = covered_stylesample_inds(stylesample_i, 3);
    if label_tested == 1
        label_str = 'Positive';
    else
        label_str = 'Negative';
    end
    mapsize = [384 256];
    id_tested = sets{style_tested}.test.samples(image_tested).id;
    starting_score = models{style_tested}.w * sets{style_tested}.test.features(image_tested, :)';
    count_patches = 0;
%     for i=1:size(patch_features, 1)
%         if str2double(patch_features{i}.id) == id_tested
%             count_patches = count_patches + 1;
%         end
%     end
    heatmap = NaN(mapsize(1), mapsize(2), (patch_dim / step)^2);
    cursor = 0;
    for i=1:size(patch_features, 1)
        if str2double(patch_features{i}.id) == id_tested
            cursor = cursor + 1;
            score = models{style_tested}.w * patch_features{i}.features';
            coords = patch_features{i}.coord;
            r = mod(coords(1) - 1, patch_dim) / step;
            c = mod(coords(2) - 1, patch_dim) / step;
            n_strato = (r * (patch_dim / step)) + c + 1;
%             if n_strato ~= 1
%                 continue
%             end
            % -(sc - s_s) is the contribution to the score from that part
            % for that style (mult is to make it opposite if positive
            % values mean negative class)
            heatmap(coords(1):coords(1) + patch_dim - 1, coords(2):coords(2) + patch_dim - 1, n_strato) = (starting_score - score) * scoreinv_mult; 
        end
    end
    heatmap_final = nanmean(heatmap, 3);
    if sum(sum(~isnan(heatmap_final))) == 0
        continue
    end
    f = figure;
%     set(f, 'Visible', 'off');
    subplot(1,3,1)
    imagesc(imresize(imread(['hipsterwars_checkered_preppy/' num2str(sets{style_tested}.test.samples(image_tested).id) '.jpg']), mapsize))
    title([names{style_tested} ' ' label_str ' Score: ', num2str(starting_score)]);
    subplot(1,3,2)
    imagesc(imresize(sets{style_tested}.test.samples(image_tested).image, mapsize))
    hold on
    h = imagesc(heatmap_final);
    hold off
    set(h, 'AlphaData', ones(mapsize) .* 0.75);
    subplot(1,3,3)
    imagesc(heatmap_final)
    colorbar
    saveas(f, ['heatmaps_checkered/' names{style_tested} '_' label_str '_' num2str(stylesample_i) '.fig']);
    close all
    delete(f);
end

%%
old_exp = load('checkpoint_py.mat', 'sets');
load preppy_heatmaps_info.mat

for stylesample_i=1:size(covered_stylesample_inds, 1)
    current_ind = covered_list(stylesample_i);
    ph_ind = find(preppy_heatmaps_info(:, 1) == current_ind);
    if isempty(ph_ind)
        continue
    end
    old_feature_vect = old_exp.sets{3}.test.features(find([old_exp.sets{3}.test.samples(:).id]' == current_ind), :);
    old_vect_new_score = models{style_tested}.w * old_feature_vect'
    imgname_ind = preppy_heatmaps_info(ph_ind, 2);
    imgs = dir(['heatmaps_py/*_' num2str(imgname_ind) '.fig']);
    uiopen(['heatmaps_py/' imgs(1).name],1);
    imgs = dir(['heatmaps_checkered/*_' num2str(stylesample_i) '.fig']);
    uiopen(['heatmaps_checkered/' imgs(1).name],1);
end

