from os.path import join, dirname
from vunit import VUnit

ghdl_elab_flags = '-g -Wbinding -Wreserved -Wlibrary -Wvital-generic -Wdelayed-checks -Wbody -Wspecs -Wunused --mb-comments --std=08 --ieee=synopsys -fexplicit'.split()
ghdl_sim_flags = ''.split()

src_path = join(dirname(__file__), '..', "src")
test_path = join(dirname(__file__), '..', "test")

def post_run(results):
    results.merge_coverage(file_name="coverage_data")

vu = VUnit.from_argv()

vu.add_library("odeSolver").add_source_files(
    [join(src_path, "*.vhdl"), join(test_path, "*.vhdl")]
)

vu.set_compile_option("ghdl.flags", ghdl_elab_flags)
vu.set_sim_option('ghdl.elab_flags', ghdl_elab_flags)
vu.set_sim_option('ghdl.sim_flags', ghdl_sim_flags)
vu.set_sim_option('ghdl.elab_e', True)

vu.set_compile_option("rivierapro.vcom_flags", ["-coverage", "bs"])
vu.set_compile_option("rivierapro.vlog_flags", ["-coverage", "bs"])
vu.set_compile_option("modelsim.vcom_flags", ["+cover=bs"])
vu.set_compile_option("modelsim.vlog_flags", ["+cover=bs"])
vu.set_sim_option("enable_coverage", True)

vu.main()
