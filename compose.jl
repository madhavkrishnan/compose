using OpenQASM
using JSON
using PythonCall



"""
    parse_qasm_prog(prog::Vector{Any})

    Split qasm program into declaration and body and return each as a vector.
"""
function parse_qasm_prog(prog::Vector{Any})

    for i in eachindex(prog)
        if typeof(prog[i]) in (OpenQASM.Types.Include, OpenQASM.Types.RegDecl)
            continue
        end
        return prog[1:i-1], prog[i:end]
    end
end

"""
Determine the maximum qubits needed given an array of qasm_progs
"""
function qmax(progs)
    qubits = 0
    for p in progs
        for line in p
            if (typeof(line) == OpenQASM.Types.RegDecl) && (line.type.str == "qreg")
                q = convert(Int, line.size)
                if q > qubits
                    qubits = q
                end
                break
            end
        end
    end
    return qubits
end

function cmax(progs)
    max_cbits = 0
    for p in progs
        cbits = 0
        for line in p
            if (typeof(line) == OpenQASM.Types.RegDecl) && (line.type.str == "creg")
                cbits += 1
            end
        end
        if cbits > max_cbits
            max_cbits = cbits
        end
    end
    return max_cbits

end



"""
    function compose(qasm_files, qdata_files; outfile="out.qasm")
    
    stiches together multiple widgets into a single qasm file

"""
function compose(qasm_files, qdata_files; outfile="out.qasm")

    qasm_strings = [OpenQASM.parse(read(f, String)).prog for f in qasm_files]
    data_qubits = [JSON.parsefile(m) for m in qdata_files]
    qasm_split = [parse_qasm_prog(p) for p in qasm_strings]
    headers = [p[1] for p in qasm_split]
    bodies = [p[2] for p in qasm_split]

    file = open(outfile, "w")

    # Create header
    println(file, "OPENQASM 2.0;\ninclude \"qelib1.inc\";")

    # Declare qregs
    println(file, "qreg q[$(qmax(headers))];")

    # Declare cregs
    for i in 0:cmax(headers)-1
        println(file, "creg c$i[1];")
    end

    # add first widget body
    for line in bodies[1]
        println(file, line)
    end

    # add remaining widgets with connecting swaps
    for (idx, b) in enumerate(bodies)
        idx == 1 && continue
        output_qubits = data_qubits[idx-1]["output"]
        state_qubits = data_qubits[idx]["state"]

        for (o, s) in zip(output_qubits, state_qubits)
            if o != s
                println(file, "swap q[$o], q[$s];")
            end
        end

        for line in b
            println(file, line)
        end
    end

    close(file)

end

# Load qasm files
qasm_files = ["mwe1_compiled.qasm", "mwe2_compiled.qasm"]
qdata_files = ["mwe1_compiled_dqubits.json", "mwe2_compiled_dqubits.json"]

compose(qasm_files, qdata_files)

qiskit = pyimport("qiskit")
circ = qiskit.QuantumCircuit.from_qasm_file("out.qasm")

print(circ)