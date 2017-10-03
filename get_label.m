function [ labels ] = get_label( samples )
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

labels = zeros(size(samples, 1), 1);

names = {'Hipster', 'Goth', 'Preppy', 'Pinup', 'Bohemian'};

for i=1:size(samples, 1)
    labels(i) = find(ismember(names, samples(i).style_name));
end

end

