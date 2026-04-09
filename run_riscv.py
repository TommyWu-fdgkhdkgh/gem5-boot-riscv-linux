import argparse
from gem5.components.boards.riscv_board import RiscvBoard
from gem5.components.cachehierarchies.classic.private_l1_private_l2_walk_cache_hierarchy import PrivateL1PrivateL2WalkCacheHierarchy
from gem5.components.memory import DualChannelDDR4_2400
from gem5.components.processors.cpu_types import CPUTypes
from gem5.components.processors.simple_processor import SimpleProcessor
from gem5.isas import ISA
from gem5.resources.resource import KernelResource, DiskImageResource, BootloaderResource
from gem5.simulate.simulator import Simulator

# -------------- add options -------------- #
parser = argparse.ArgumentParser()
parser.add_argument(
    '--cpu-type',
    action="store",
    dest='cpu_type',
    required=False,
    default="atomic",
    choices=['atomic', 'timing', 'minor', 'o3'],
    help='The type of the CPU model',
)
parser.add_argument(
    '--num-cores',
    action="store",
    type=int,
    dest='num_cores',
    required=False,
    default=3,
    help='The number of cores',
)

# ---------------------------- Parse Options --------------------------- #
args = parser.parse_args()

cache_hierarchy = PrivateL1PrivateL2WalkCacheHierarchy(
    l1d_size="16KiB", l1i_size="16KiB", l2_size="256KiB"
)

memory = DualChannelDDR4_2400(size="3GiB")

print(f"num-cores : {args.num_cores}")
if args.cpu_type == "atomic":
    print("cpy_type : atomic")
    processor = SimpleProcessor(
        cpu_type=CPUTypes.ATOMIC, isa=ISA.RISCV, num_cores=args.num_cores
    )
elif args.cpu_type == "timing":
    print("cpy_type : timing")
    processor = SimpleProcessor(
        cpu_type=CPUTypes.TIMING, isa=ISA.RISCV, num_cores=args.num_cores
    )
    pass
elif args.cpu_type == "minor":
    print("cpy_type : minor")
    processor = SimpleProcessor(
        cpu_type=CPUTypes.MINOR, isa=ISA.RISCV, num_cores=args.num_cores
    )
elif args.cpu_type == "o3":
    print("cpy_type : o3")
    processor = SimpleProcessor(
        cpu_type=CPUTypes.O3, isa=ISA.RISCV, num_cores=args.num_cores
    )
else:
    assert False

board = RiscvBoard(
    clk_freq="3GHz",
    processor=processor,
    memory=memory,
    cache_hierarchy=cache_hierarchy,
)

kernel = KernelResource(local_path="./opensbi/build/platform/generic/firmware/fw_payload.elf")
disk_image = DiskImageResource(local_path="./buildroot/output/images/rootfs.ext4")

board.set_kernel_disk_workload(
    kernel=kernel,
    disk_image=disk_image,
    kernel_args=["console=ttyS0", "earlycon=uart8250,mmio,0x10000000", "root=/dev/vda", "rw"]
)

simulator = Simulator(board=board)
print("Starting simulation...")
simulator.run()
