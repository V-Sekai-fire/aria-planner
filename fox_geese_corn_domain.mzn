% MiniZinc model for domain: domain
% Generated from planner elements using Sourceror

% Variable declarations
var bool: east_fox;
var bool: east_geese;
var bool: east_corn;
var bool: west_fox;
var bool: west_geese;
var bool: west_corn;
var bool: boat_location;

% Constraints from commands
% No command constraints

% Constraints from tasks
% No task constraints

% Constraints from multigoals
% No multigoal constraints

solve satisfy;
