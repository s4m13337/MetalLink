:Begin:
:Function:       deviceName
:Pattern:        DeviceName[]
:Arguments:      {}
:ArgumentTypes:  {}
:ReturnType:     String
:End:

:Begin:
:Function:       deviceRecommendedMaxWorkingSetSize
:Pattern:        DeviceMemory[]
:Arguments:      {}
:ArgumentTypes:  {}
:ReturnType:     Manual
:End:

:Begin:
:Function:       deviceHasUnifiedMemory
:Pattern:        DeviceMemoryType[]
:Arguments:      {}
:ArgumentTypes:  {}
:ReturnType:     String
:End:

:Begin:
:Function:       deviceMaxTransferRate
:Pattern:        DeviceMaxTransferRate[]
:Arguments:      {}
:ArgumentTypes:  {}
:ReturnType:     Manual
:End:

:Begin:
:Function:       deviceMaxBufferLength
:Pattern:        DeviceMaxBufferLength[]
:Arguments:      {}
:ArgumentTypes:  {}
:ReturnType:     Manual
:End:

:Begin:
:Function:       addArrays
:Pattern:        AddArrays[ i_List, j_List]
:Arguments:      { i, j }
:ArgumentTypes:  { Manual }
:ReturnType:     Manual
:End:

:Evaluate: DeviceName::usage = "Get information about metal device."
:Evaluate: DeviceMemory::usage = "Get recommended usable memory of metal device."
:Evaluate: DeviceMemoryType::usage = "Whether unified/dedicated."
:Evaluate: DeviceMaxTransferRate::usage = "Transfer rate in Bytes/Second between CPU and GPU"
:Evaluate: AddArrays::usage = "Add two arrays"