if ~exist('features')
    load styleDescriptor.mat
    load hipsterwars_Jan_2014.mat
end

%normalizza
[ normalized_features, feature_avgs, feature_stds ] = normalize_features_fn( features );
names = {'Hipster', 'Goth', 'Preppy', 'Pinup', 'Bohemian'};
for i=1:length(names)
    names{i}
    %for delta=0.1:0.1:0.5
    for delta=[0.2]
        ind_list = get_indexes_by_style( samples, names{i} );
        style_features = normalized_features(ind_list, :);
        style_samples = samples(ind_list);
        [top_ind_list, ~] = get_indexes_by_top_perc( style_samples, delta );
        [~, bottom_ind_list] = get_indexes_by_top_perc( style_samples, 1.0 - delta );
        style_samples = [style_samples(top_ind_list); style_samples(bottom_ind_list)];
        style_features = [style_features(top_ind_list, :); style_features(bottom_ind_list, :)];
        labels = zeros(numel(top_ind_list) + numel(bottom_ind_list), 1);
        labels(1:numel(top_ind_list)) = 1; %positivi
        labels(numel(top_ind_list) + 1:end) = 2; %negativi
        perm = randperm(numel(top_ind_list) + numel(bottom_ind_list));
        style_features = style_features(perm, :);
        labels = labels(perm);
        C = train(labels, sparse(style_features), '-s 2 -C -v 5 -q');
        %model = train(labels, sparse(style_features), ['-s 2 -c ', num2str(C(1)), ' -v 10 -q']);
        %model = train(labels, sparse(style_features), ['-s 2 -v 10 -q']);
    end
end