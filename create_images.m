function [ ] = create_images( )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
src_path = ('hipsterwars_segmentation_results/');
dst_path = ('hipsterwars_segmentation_results_colormap/');
imgs = dir([src_path '*.png']);

cmap56 = get_cmap(56);

for i=1:length(imgs)
    if mod(i, 50) == 0
       i 
    end
    imgname = imgs(i).name;
    img = imread([src_path imgname]);
    new_img = zeros(size(img));
    img = img(:, :, 1);
    for r=1:size(img, 1)
        for c=1:size(img, 2)
            new_img(r,c,:) = cmap56(img(r,c), :);
        end
    end
    imwrite(new_img, [dst_path imgname]);
end

end

