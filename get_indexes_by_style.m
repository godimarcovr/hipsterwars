function ind_list = get_indexes_by_style( samples, style )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

for i=1:size(samples, 1)
    if strcmp(samples(i).style_name, style)
        start_ind = i;
        break
    end
end

for i=start_ind:size(samples, 1)
    if ~strcmp(samples(i).style_name, style) || i == size(samples, 1)
        end_ind = i;
        break
    end
end

ind_list = start_ind:end_ind-1;
end

