% Fox-Geese-Corn Problem Instance
% f=1, g=1, c=1, k=2

var 0..1: west_fox;
var 0..1: west_geese;
var 0..1: west_corn;
var 0..1: east_fox;
var 0..1: east_geese;
var 0..1: east_corn;
var bool: boat_west;

% Initial state constraints
constraint west_fox = 1;
constraint west_geese = 1;
constraint west_corn = 1;
constraint east_fox = 0;
constraint east_geese = 0;
constraint east_corn = 0;
constraint boat_west = true;

% Safety constraints: fox cannot be alone with geese
constraint (west_fox = 0) / (west_geese = 0) / (west_corn > 0);
constraint (east_fox = 0) / (east_geese = 0) / (east_corn > 0);

% Safety constraints: geese cannot be alone with corn
constraint (west_geese = 0) / (west_corn = 0) / (west_fox > 0);
constraint (east_geese = 0) / (east_corn = 0) / (east_fox > 0);

% Goal: all items on east side
constraint east_fox = 1;
constraint east_geese = 1;
constraint east_corn = 1;

solve satisfy;
