# Real-Time evaluation of `Web-Assembly`
-----------------------

## Setup
1. run `setup_rt_linux.sh` to download the version 7.2 of the Linux kernel and the relative real-time patch. The script patch the kernel and enable PREEMPT-RT.

2. Compile the kernel:
```
make -j8
```

3. Initialize the submodules of this repo:
```
git submodule init
```

4. Compile staically the `cyclictest`:
```
cd rt-tests
make NUMA=0 LDFLAGS="-static" cyclictest  
mv cyclictest ../
cd ../
```

5. copy the executable file in the filesystem which will be used by QEMU:
```
./init_fs.sh
```

6. Start QEMU:
```
sudo qemu-system-x86_64 \
    -kernel kernels/linux-7.2-rt/arch/x86/boot/bzImage \
    -initrd test.gz \
    -append "root=/dev/sda2 rw console=ttyS0 idle=poll processor.max_cstate=0 tsc=reliable" \
    -m 2G \
    -object memory-backend-file,id=mem,size=2G,mem-path=/dev/hugepages,share=on,prealloc=yes \
    -machine pc,memory-backend=mem \
    -smp 2,sockets=1,cores=2,threads=1 \
    -nographic \
    -enable-kvm \
    -cpu host,migratable=no,+invtsc \
    -name debug-threads=on \
    -drive file=benchmark.img,format=raw,media=disk
```

7. Mount the shared FS and run the test:
```
mkdir -p /mnt/data
sudo mount /dev/sda /mnt/data
cd /
sudo ./cyclictest -p 99 -m -i 1000 -D 60s > /mnt/data/baseline.txt
sudo umount /mnt/data
```


