%% carica dataset hipsterwars
if ~exist('features')
    load styleDescriptor.mat
    load hipsterwars_Jan_2014.mat
end
[top_ind_list, bottom_ind_list] = get_indexes_by_top_perc_everyclass( samples, 0.15 );
[ train_samples, train_labels, ~, ~ ] = create_between_training( samples(top_ind_list), features(top_ind_list, :), 1:size(top_ind_list, 2));

%% training
ntot = length(train_labels);
% ntot = 79;
train_perc = 1.0;

perm = randperm(ntot);
test_inds = perm(ceil(train_perc * ntot) + 1:end);
test_labels = train_labels(test_inds);
test_samples = train_samples(test_inds, :);
train_inds = perm(1:ceil(train_perc * ntot));
train_labels = train_labels(train_inds);
train_samples = train_samples(train_inds, :);

% questo ha ottenuto 71%!
% load top50features.mat
% labels = [ones(1,50)';2*ones(1,50)';3*ones(1,50)';4*ones(1,50)';5*ones(1,50)'];
% model = train(labels, sparse(topfeatures), '-s 2 -v 10');

[ train_samples, feature_avgs, feature_stds ] = normalize_features_fn( train_samples );
model = train(train_labels, sparse(train_samples), '-s 2 -v 10');
%model = train(train_labels, sparse(train_samples), '-s 2 -c 0.0001 -p 0.1 -v 10');
% model = train(train_labels, sparse(train_samples), '-s 1 -c 0.0001 -p 0.1');

%% testing
% [predicted_label, accuracy, decision_values] = predict(test_labels, sparse(test_samples), model);



