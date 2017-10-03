function [top_ind_list, bottom_ind_list] = get_indexes_by_top_perc_everyclass( samples, delta )

names = {'Hipster', 'Goth', 'Preppy', 'Pinup', 'Bohemian'};

top_ind_list = [];
bottom_ind_list = [];

for name=names
    ind_list = get_indexes_by_style( samples, name );
    base = min(ind_list) - 1;
    [tmp_top_ind_list, tmp_bottom_ind_list] = get_indexes_by_top_perc( samples(ind_list), delta );
    tmp_top_ind_list = tmp_top_ind_list + base;
    tmp_bottom_ind_list = tmp_bottom_ind_list + base;
    top_ind_list = [top_ind_list tmp_top_ind_list];
    bottom_ind_list = [bottom_ind_list tmp_bottom_ind_list];
end

end

