function [ train_samples, train_labels, test_samples, test_labels ] = create_between_training( samples, features, train_indexes)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

%crea output dati degli elementi con rispettive features e indici per il
%training set
%(i random split verranno generati da un'altra funzione)

train_samples = features(train_indexes, :);
train_labels = get_label(samples(train_indexes));

test_indexes = setdiff(1:size(features, 1), train_indexes);

test_samples = features(test_indexes, :);
test_labels = get_label(samples(test_indexes));

end

