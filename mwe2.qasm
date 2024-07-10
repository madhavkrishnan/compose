OPENQASM 2.0;
include "qelib1.inc";
// comment
qreg q[2];
rz(0.3) q[0];
cx q[0],q[1];