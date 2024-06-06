## Generate the minimal system: 
```Makefile
make bootrom
make sw
make rtl CFG=snax_minimal.hjson
make occamy_system_vivado_preparation SNAX_MINIMAL=1
make occamy_ip_vcu128
make occamy_system_vcu128
```

## Generate the maximal system: 
```Makefile
make bootrom
make sw
make rtl CFG=snax_two_clusters.hjson
make occamy_system_vivado_preparation
make occamy_ip_vcu128
make occamy_system_vcu128
```

## Simulate the minimal system: 
```Makefile
make bootrom
make sw
make rtl CFG=snax_minimal.hjson
make occamy_system_vsim_preparation SNAX_MINIMAL=1
make occamy_system_vsim
```

## Simulate the normal system: 

```Makefile
make bootrom
make sw
make rtl CFG=snax_two_clusters.hjson
make occamy_system_vsim_preparation
make occamy_system_vsim
```