clc;
clear;
close all;
dbstop if error
warning off
 addpath(genpath(pwd));
addpath('sub_functions')


ch=menu('Select your choice','Run main program','feature extraction','Plot the results','Restore default data');
if ch==1
    run_classification_holdout
    run_classification_kfold_p4
    run_performance_holdout_p4%algo 
run_performance_holdout1_p4
elseif ch==2
    main_feat_extract_p4
elseif ch==3
    plot_graph_all_p4
elseif ch==4
    restore_bkup_data
end

