if ~exist('features')
    %load features_stylenet.mat
    load hipsterwars_Jan_2014.mat
    features = hdf5read('features_stylenet.h5', '/features');
    features = double(features');
end

train_perc = 0.9;
delta = 0.2;
names = {'Hipster', 'Goth', 'Preppy', 'Pinup', 'Bohemian'};

sets = cell(length(names), 1);
train_features = zeros(0, size(features, 2));
%% split
for i=1:length(names)
    ind_list = get_indexes_by_style( samples, names{i} );
    style_features = features(ind_list, :);
    style_samples = samples(ind_list);
    
    [top_ind_list, ~] = get_indexes_by_top_perc( style_samples, delta );
    [~, bottom_ind_list] = get_indexes_by_top_perc( style_samples, 1.0 - delta );
    style_samples = [style_samples(top_ind_list); style_samples(bottom_ind_list)];
    style_features = [style_features(top_ind_list, :); style_features(bottom_ind_list, :)];
    
    labels = zeros(numel(top_ind_list) + numel(bottom_ind_list), 1);
    labels(1:numel(top_ind_list)) = 1; %positivi
    labels(numel(top_ind_list) + 1:end) = 2; %negativi
    
    ntot = numel(top_ind_list) + numel(bottom_ind_list);
    perm = randperm(ntot);
    
    style_test_inds = perm(ceil(train_perc * ntot) + 1:end);
    style_test_labels = labels(style_test_inds);
    style_test_samples = style_samples(style_test_inds, :);
    style_test_features = style_features(style_test_inds, :);
    
    style_train_inds = perm(1:ceil(train_perc * ntot));
    style_train_labels = labels(style_train_inds);
    style_train_samples = style_samples(style_train_inds, :);
    style_train_features = style_features(style_train_inds, :);
    
    sets{i}.train.labels = style_train_labels;
    sets{i}.train.samples = style_train_samples;
    sets{i}.train.features = style_train_features;

    sets{i}.test.labels = style_test_labels;
    sets{i}.test.samples = style_test_samples;
    sets{i}.test.features = style_test_features;
    
    train_features = [train_features; style_train_features];
end

%% train models
% [ normalized_train_features, train_feature_avgs, train_feature_stds ] = normalize_features_fn( train_features );
models = cell(length(names), 1);
for i=1:length(names)
    names{i}
    % [normalized_style_train_features, ~, ~] = normalize_features_fn(sets{i}.train.features, train_feature_avgs, train_feature_stds);
    C = train(sets{i}.train.labels, sparse(sets{i}.train.features), '-s 0 -C -v 5 -q');
    models{i} = train(sets{i}.train.labels, sparse(sets{i}.train.features), ['-s 0 -c ', num2str(C(1)), ' -q']);
end

%%
covered_list = [];
covered_stylesample_inds = [];
number_of_samples = -1; %n or -1
for style_i=1:length(names)
    tmp_testset = sets{style_i}.test.samples;
    [~,index] = sortrows([tmp_testset.style_skill].'); tmp_testset = tmp_testset(index(end:-1:1));
    tmp_labels = sets{style_i}.test.labels(index);
%     covered_list = [covered_list; tmp_testset(1).id; tmp_testset(end).id];
%     covered_list = [covered_list; tmp_testset(1).id; tmp_testset(2).id; tmp_testset(end - 1).id; tmp_testset(end).id];
    if number_of_samples < 0
        covered_list = [covered_list; [tmp_testset(:).id]'];
        covered_stylesample_inds = [covered_stylesample_inds; [ones(size(index,1), 1).*style_i index(end:-1:1) tmp_labels(end:-1:1)]];
    else
        for i=1:number_of_samples
            covered_list = [covered_list; tmp_testset(i).id];
        end
        for i=size(tmp_labels, 1)-number_of_samples+1:size(tmp_labels, 1)
            covered_list = [covered_list; tmp_testset(i).id];
        end
        for i=size(tmp_labels, 1):-1:size(tmp_labels, 1)-number_of_samples+1
            covered_stylesample_inds = [covered_stylesample_inds; style_i index(i) tmp_labels(i)];
        end
        for i=number_of_samples:-1:1
            covered_stylesample_inds = [covered_stylesample_inds; style_i index(i) tmp_labels(i)];
        end
    end
%     covered_stylesample_inds = [covered_stylesample_inds; style_i index(end) tmp_labels(end); style_i index(1) tmp_labels(1)];
%     covered_stylesample_inds = [covered_stylesample_inds; style_i index(end) tmp_labels(end); style_i index(end-1) tmp_labels(end-1); style_i index(2) tmp_labels(2); style_i index(1) tmp_labels(1)];
end

% preppy_heatmaps_info = [covered_list(covered_stylesample_inds(:, 1) == 3) find(covered_stylesample_inds(:, 1) == 3)];
% save preppy_heatmaps_info.mat preppy_heatmaps_info

%%
features = hdf5read('features_stylenet_covered.h5', '/features');
features = squeeze(features);
features = double(features');
info = hdf5read('features_stylenet_covered.h5', '/info');
info = info';
patch_features = cell(size(info, 1), 1);
for i=1:size(info, 1)
    patch_features{i}.features = features(i, :);
    patch_features{i}.coord = info(i, 2:3);
    patch_features{i}.id = num2str(info(i, 1));
end

%%
counters = zeros(size(patch_features, 1), 1);
for i=1:size(patch_features, 1)
    counters(i) = str2double(patch_features{i}.id);
end
unique(counters)
% sum(counters == 16683)



%%
patch_dim = 48;
step = 16;
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
    for i=1:size(patch_features, 1)
        if str2double(patch_features{i}.id) == id_tested
            count_patches = count_patches + 1;
        end
    end
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
            % -(sc - s_s) is the contribution to the score from that part
            % for that style (mult is to make it opposite if positive
            % values mean negative class)
            heatmap(coords(1):coords(1) + patch_dim - 1, coords(2):coords(2) + patch_dim - 1, n_strato) = -(score - starting_score) * scoreinv_mult; 
        end
    end
    heatmap_final = nanmean(heatmap, 3);
    if sum(sum(~isnan(heatmap_final))) == 0
        continue
    end
    f = figure;
%     set(f, 'Visible', 'off');
    subplot(1,3,1)
    imagesc(imresize(sets{style_tested}.test.samples(image_tested).image, mapsize))
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
    saveas(f, ['heatmaps_py/' names{style_tested} '_' label_str '_' num2str(stylesample_i) '.fig']);
    close all
    delete(f);
end



