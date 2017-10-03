function [ normalized_features, feature_avgs, feature_stds ] = normalize_features_fn( features, feature_avgs, feature_stds )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
if nargin <= 1
    feature_avgs = mean(features, 1);
    feature_stds = std(features, 0, 1); 
end

normalized_features = bsxfun(@rdivide,bsxfun(@minus,features,feature_avgs), feature_stds);
end

