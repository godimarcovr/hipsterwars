%% load
% clear all
% load hipsterwars_Jan_2014.mat %samples
nstyles = 5;
nitems = 56;
labels = get_label(samples);
tot_per_class = zeros(nstyles, 1);
names = {'Hipster', 'Goth', 'Preppy', 'Pinup', 'Bohemian'};
for i=1:length(names)
    tot_per_class(i) = length(get_indexes_by_style( samples, names{i} ));
end
%removed background class
item_labels = {'null', 'tights', 'shorts', 'blazer', 't-shirt', 'bag', 'shoes', 'coat', 'skirt', 'purse', 'boots', 'blouse', 'jacket', 'bra', 'dress', 'pants', 'sweater', 'shirt', 'jeans', 'leggings', 'scarf', 'hat', 'top', 'cardigan', 'accessories', 'vest', 'sunglasses', 'belt', 'socks', 'glasses', 'intimate', 'stockings', 'necklace', 'cape', 'jumper', 'sweatshirt', 'suit', 'bracelet', 'heels', 'wedges', 'ring', 'flats', 'tie', 'romper', 'sandals', 'earrings', 'gloves', 'sneakers', 'clogs', 'watch', 'pumps', 'wallet', 'bodysuit', 'loafers', 'hair', 'skin'};
paper_labels = [6, 28, 4, 12, 11, 24, 8, 15, 55, 39, 13, 19, 20, 16, 18, 7, 3, 56, 9, 17, 2, 23];
%paper_labels = paper_labels - 1;

%% compute histogram
src_path = ('hipsterwars_segmentation_results/');

style_item_histogram = zeros(nstyles, nitems);
pixelcounts_by_style = cell(nstyles , 1);
for i=1:nstyles
    pixelcounts_by_style{i} = zeros(0, nitems);
end
tot_per_class = repmat(tot_per_class, 1, nitems);
for i=1:size(samples, 1)
    if mod(i, 50) == 0
       i 
    end
    imgname = samples(i).id;
    [present_labels, label_n_pixels] = get_img_items( [src_path num2str(imgname) '.png'] );
    tmp_counts = zeros(1, nitems);
    tmp_counts(present_labels) = label_n_pixels;
    pixelcounts_by_style{labels(i)} = [pixelcounts_by_style{labels(i)}; tmp_counts];
    style_item_histogram(labels(i), present_labels) = style_item_histogram(labels(i), present_labels) + 1;
end
% media senza togliere gli zeri
average_size_all = zeros(nstyles, nitems);
for i=1:nstyles
    average_size_all(i, :) = mean(pixelcounts_by_style{i});
end
% media togliendo gli zeri
average_size_nozeros = zeros(nstyles, nitems);
for i=1:nstyles
    for j=1:nitems
        average_size_nozeros(i, j) = mean(pixelcounts_by_style{i}(find(pixelcounts_by_style{i}(:, j) ~= 0), j));
    end
end

% style_item_histogram = style_item_histogram ./ tot_per_class;
% style_item_histogram = style_item_histogram(:, paper_labels);
% style_item_histogram = style_item_histogram';
% bar(1:size(style_item_histogram, 1), style_item_histogram)
% set(gca,'xticklabel',item_labels(paper_labels))
% set(gca,'XTickLabelRotation',45)
% set(gca,'xtick',1:size(style_item_histogram, 1));
average_size_all = average_size_all(:, paper_labels);
average_size_all = average_size_all';
bar(1:size(average_size_all, 1), average_size_all)
set(gca,'xticklabel',item_labels(paper_labels ))
set(gca,'XTickLabelRotation',45)
set(gca,'xtick',1:size(average_size_all, 1));
figure
average_size_nozeros = average_size_nozeros(:, paper_labels);
average_size_nozeros = average_size_nozeros';
bar(1:size(average_size_nozeros, 1), average_size_nozeros)
set(gca,'xticklabel',item_labels(paper_labels))
set(gca,'XTickLabelRotation',45)
set(gca,'xtick',1:size(average_size_nozeros, 1));

