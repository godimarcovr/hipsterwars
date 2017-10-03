function ind = find_ind_fn(imgs, nam)
    ind = 0;
    for j=1:size(imgs, 1)
        if strcmp(imgs(j).name, [num2str(nam) '.jpg'])
            ind = j;
            break
        end
    end
end