function ind = find_samples_line_from_id_fn( samples, id )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
ind = -1;

for i=1:size(samples, 1)
    if samples(i).id == id
        ind = i;
        break
    end
end

end

