
$fs = 0.01; // min angle for curved shapes
$fa = 2; // min segment/fragment size

RAD = 180 / PI;
DEG = 1;

epsilon = 0.001;

module diffscale() {
     for (i = [0 : $children-1]) {
         translate([-epsilon/2,-epsilon/2,-epsilon/2]) scale([1+epsilon,1+epsilon,1+epsilon]) children(i);
     }
}

module rounded_rect(size, radius, center=false, epsilon=0.01) {
    centertranslation = center ? [-size.x/2, -size.y/2, -size.z/2] : [0,0,0];
    module fillet(r, h) {
        translate([r/2, r/2, 0]) difference() {
            cube([r + epsilon, r + epsilon, h], center = true);
            translate([r/2, r/2, 0])
                cylinder(r = r, h = h + 1, center = true);
        }
    }
    translate(centertranslation) difference() {
        cube(size);
        translate([0,0,size.z/2]) fillet(radius,size.z+0.001);
        translate([size.x,0,size.z/2]) rotate(PI/2*RAD, [0,0,1]) fillet(radius, size.z+epsilon);
        translate([0,size.y,size.z/2]) rotate(-PI/2*RAD, [0,0,1]) fillet(radius, size.z+epsilon);
        translate([size.x,size.y,size.z/2]) rotate(PI*RAD, [0,0,1]) fillet(radius, size.z+epsilon);
    }
}


strand_width = 17.2;
strand_thickness = 6 + 1;
strand_count = 8;
drill_spacing = 152;
screw_radius_major = 1.65;
screw_radius_head = 3.2;
drill_radius = screw_radius_major+0.4;

base_size = [30, drill_spacing + 12, 2];

divider_thickness = 0.8;

// platform
difference() {
    union() {
        rounded_rect(base_size, 10);
        // drill base
        for (i = [0:1]) {
            translate([base_size.x/2, i * drill_spacing + (base_size.y-drill_spacing)/2, 0]) rotate([0,0,PI/4*RAD]) cylinder(h=base_size.z*2.2, r1=drill_radius+2.2, r2=screw_radius_head);
        }
    }
    // drills
    union() {
        for (i = [0:1]) {
            translate([base_size.x/2, i * drill_spacing + (base_size.y-drill_spacing)/2, 0]) cylinder(h=base_size.z*2.3, r=drill_radius);
        }
    }
}

// grooves
divider_support_radius = 2;
lip_overhang = 0.8;
slight_y_correction = -0.4;

for (i = [0 : strand_count]) {
    translate([0, (base_size.y - strand_count*(strand_width + divider_thickness))/2 + (strand_width + divider_thickness)*i + slight_y_correction, 0]) {
        cube([base_size.x, divider_thickness, base_size.z+strand_thickness]);
        
        // lip
        lip_thickness = 0.6;
        translate([0,-lip_overhang,base_size.z+strand_thickness]) cube([base_size.x, divider_thickness+lip_overhang*2, lip_thickness]);
        translate([0,-lip_overhang/2,base_size.z+strand_thickness-lip_thickness/2]) cube([base_size.x, divider_thickness+lip_overhang, lip_thickness/2]);
        
        // extra supports
        for (s = [0 : 4]) {
            translate([divider_thickness + s*(base_size.x-divider_thickness)/4,divider_thickness/2,base_size.z+divider_support_radius/2]) rotate([0,-PI/2*RAD,0]) cylinder(divider_thickness,r=divider_support_radius,$fn=3);
        }
    }
}


// top ring
eyelet_length = base_size.x/3;
eyelet_radius = 5;
eyelet_inner = 2;
translate([(base_size.x - eyelet_length)/2, base_size.y+eyelet_radius/1.5, eyelet_radius]) rotate([0,PI/2*RAD,0]) difference() {
    cylinder(h=eyelet_length, r=eyelet_radius);
    translate([0,0,-epsilon*4]) cylinder(h=eyelet_length*2, r=eyelet_radius-eyelet_inner);
}
translate([(base_size.x - eyelet_length)/2, base_size.y, 0]) {
    cube([eyelet_length, eyelet_radius-eyelet_inner, eyelet_inner]);
    translate([0,0,0.3]) rotate([-14*DEG,0,0]) translate([0, -2.9, 0]) cube([eyelet_length, eyelet_inner, eyelet_radius]);
}
