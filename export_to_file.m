function export_to_file( samples )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

basefolder = 'hipsterwars_dataset/';
if ~exist(basefolder)
    mkdir(basefolder);
end
for i=1:size(samples, 1)
    i
    imwrite(samples(i).image, [basefolder num2str(samples(i).id) '.jpg']);
end

end

