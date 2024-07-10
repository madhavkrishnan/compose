using Jabalizer
using PythonCall

# circ_id = "mwe"
# circ_id = "mwe1"
circ_id = "mwe2"
ip_file = circ_id*".qasm"

qc = parse_file(ip_file)

outfile = circ_id*"_compiled.qasm"
mdata = mbqccompile(qc, pcorrections=true)

qasm_instruction(outfile, mdata)

qiskit = pyimport("qiskit")

c1 = qiskit.QuantumCircuit.from_qasm_file("mwe1_compiled.qasm")
c2 = qiskit.QuantumCircuit.from_qasm_file("mwe2_compiled.qasm")
print(c1)
print(c2)
