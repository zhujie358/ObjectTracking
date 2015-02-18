if isempty(currentFigures), currentFigures = []; end;
close(setdiff(findall(0, 'type', 'figure'), currentFigures))
clear mex
delete *.mexw64
[~,~,~] = rmdir('P:\ObjectTracking-master\coderdemo_kalman_filter\codegen','s');
clear P:\ObjectTracking-master\coderdemo_kalman_filter\ObjTrack.m
delete P:\ObjectTracking-master\coderdemo_kalman_filter\ObjTrack.m
clear P:\ObjectTracking-master\coderdemo_kalman_filter\kalman_loop.m
delete P:\ObjectTracking-master\coderdemo_kalman_filter\kalman_loop.m
clear P:\ObjectTracking-master\coderdemo_kalman_filter\kalmanfilter.m
delete P:\ObjectTracking-master\coderdemo_kalman_filter\kalmanfilter.m
clear P:\ObjectTracking-master\coderdemo_kalman_filter\plot_trajectory.m
delete P:\ObjectTracking-master\coderdemo_kalman_filter\plot_trajectory.m
delete P:\ObjectTracking-master\coderdemo_kalman_filter\position.mat
clear
load old_workspace
delete old_workspace.mat
delete P:\ObjectTracking-master\coderdemo_kalman_filter\cleanup.m
cd P:\ObjectTracking-master
rmdir('P:\ObjectTracking-master\coderdemo_kalman_filter','s');
