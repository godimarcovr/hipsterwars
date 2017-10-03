function [present_labels, label_n_pixels] = get_img_items( srcpath )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

img = imread(srcpath);
img = img(:, :, 1);
present_labels = unique(img);
label_n_pixels = [];
for label=present_labels'
    label_n_pixels = [label_n_pixels length(img(img == label))];
end
label_n_pixels = label_n_pixels ./ numel(img);

end

