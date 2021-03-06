//+
Point(1) = {-3, -3, 0, 1.0};
//+
Point(2) = {-3, 3, 0, 1.0};
//+
Point(3) = {3, 3, 0, 1.0};
//+
Point(4) = {3, -3, 0, 1.0};
//+
Point(5) = {0, 0, 0, 1.0};
//+
Point(6) = {0.2, 0, 0, 1.0};
//+
Point(7) = {-0.2, 0, 0, 1.0};
//+
Line(1) = {2, 1};
//+
Line(2) = {1, 4};
//+
Line(3) = {4, 3};
//+
Line(4) = {3, 2};
//+
Circle(5) = {7, 5, 6};
//+
Circle(6) = {6, 5, 7};
//+
Curve Loop(1) = {6, 5};
//+
Plane Surface(1) = {1};
//+
Curve Loop(2) = {4, 1, 2, 3};
//+
Plane Surface(2) = {1, 2};
//+
Physical Curve("Dirichlet_Boundary") = {1, 4, 3, 2};
//+
Physical Surface("Medium") = {2};
//+
Physical Surface("Wire") = {1};
