using { /Verse.org/Concurrency }
using { /Verse.org/Simulation }
using { /Verse.org/Simulation/Tags }
using { /Fortnite.com/Devices }

using { SBI_Objects.SBI_EnvironmentGeneration }

# Queue Interface
queue_interface(t:type) := interface:

    Offer<public>(Element : t):void

    Poll<public>()<transacts><decides>:t

    Size<public>():int

    IsEmpty<public>()<transacts><decides>:void

# Comparable Queue Interface
comparable_queue_interface(t:subtype(comparable)) := class<abstract>(queue_interface(t)):

    Find(Element : t)<transacts><decides>:void

# Chunk Queue
chunk_queue<public> := class(comparable_queue_interface(sbi_environment_chunk)):

    var Elements : []sbi_environment_chunk = array{}

    GetArray<public>():[]sbi_environment_chunk =
        return Elements

    Offer<override>(Element : sbi_environment_chunk):void =
        set Elements += array{Element}
    
    Poll<override>()<transacts><decides>:sbi_environment_chunk =
        Polled := Elements[0]
        Removed := Elements.RemoveElement[0]
        set Elements = Removed
        Polled

    Size<override>():int =
        Elements.Length

    IsEmpty<override>()<transacts><decides>:void =
        Elements.Length < 0

    Find<override>(Chunk : sbi_environment_chunk)<transacts><decides>:void =
        Elements.Find[Chunk]

# Explosive Queue, encapsulate @editable member, Offer, Poll, Etc
spawn_explosive_queue<public> := class(tag){}
# explosive_queue := class<concrete>(queue_interface(explosive_device)):

#     @editable       var Elements : []explosive_device = array{}

#     Offer<override>(Element : explosive_device):void =
#         set Elements += array{Element}

#     Poll<override>()<transacts><decides>:explosive_device =
#         Polled := Elements[0]
#         Removed := Elements.RemoveElement[0]
#         set Elements = Removed
#         Polled

#     Size<override>():int =
#         Elements.Length

#     IsEmpty<override>()<transacts><decides>:void =
#         Elements.Length < 0

# Device Queue
device_queue<public> := class<concrete>(queue_interface(creative_device_base)):

    var Elements : []creative_device_base = array{}

    Offer<override>(Element : creative_device_base):void =
        set Elements += array{Element}

    Poll<override>()<transacts><decides>:creative_device_base =
        Polled := Elements[0]
        Removed := Elements.RemoveElement[0]
        set Elements = Removed
        Polled

    Size<override>():int =
        Elements.Length

    IsEmpty<override>()<transacts><decides>:void =
        Elements.Length < 0

prop_queue<public> := class<concrete>(queue_interface(creative_prop)):

    @editable       var Elements : []creative_prop = array{}

    Offer<override>(Element : creative_prop):void =
        set Elements += array{Element}

    Poll<override>()<transacts><decides>:creative_prop =
        Polled := Elements[0]
        Removed := Elements.RemoveElement[0]
        set Elements = Removed
        Polled

    Size<override>():int =
        Elements.Length

    IsEmpty<override>()<transacts><decides>:void =
        Elements.Length < 0


# Teleporter Queue, encapsulate @editable member, Offer, Poll, Etc
spawn_teleporter_queue<public> := class(tag){}
# teleporter_queue := class<concrete>(queue_interface(teleporter_device)):

#     @editable       var Elements : []teleporter_device = array{}

#     Offer<override>(Element : teleporter_device):void =
#         set Elements += array{Element}

#     Poll<override>()<transacts><decides>:teleporter_device =
#         Polled := Elements[0]
#         Removed := Elements.RemoveElement[0]
#         set Elements = Removed
#         Polled

#     Size<override>():int =
#         Elements.Length

#     IsEmpty<override>()<transacts><decides>:void =
#         Elements.Length < 0

# Agent Queue, Offer, Poll, Etc
agent_queue<public> := class(comparable_queue_interface(agent)):

    var Elements : []agent = array{}

    Offer<override>(Element : agent):void =
        set Elements += array{Element}

    Poll<override>()<transacts><decides>:agent =
        Polled := Elements[0]
        Removed := Elements.RemoveElement[0]
        set Elements = Removed
        Polled

    Size<override>():int =
        Elements.Length
    
    IsEmpty<override>()<transacts><decides>:void =
        Elements.Length <= 0
    
    Find<override>(Element : agent)<transacts><decides>:void =
        Elements.Find[Element]

positive_float := type{_X:float where 1.000000 <= _X, _X <= Inf}

normalized_range := type{_X:float where 0.000000 <= _X, _X <= 1.000000}

# Mutable Logic Data member that can be added to Parametrics
mutable_logic_data_member := class:
    
    # The Logic Value to use
    var LogicValue : logic = false

# Temporary Fix for Spawn not working
spawn_instant(t:type) := class(awaitable()):

    # Suspending Function
    Func : type{_(:t)<suspends>:any}
    # If the Task is Completed
    IsCompleted : mutable_logic_data_member = mutable_logic_data_member{}
    # Event that Signales when Task is Completed
    CompletedEvent : event() = event(){}

    # Psuedo Spawn
    Spawn(Params : t):spawn_instant(t) =
        spawn{CallSuspendingFunction(Params)}
        Self

    # Call Suspending Function and update when it is Completed and Signal
    CallSuspendingFunction(Params : t)<suspends>:void =
        Func(Params)
        set IsCompleted.LogicValue = true
        CompletedEvent.Signal()

    # Await Function
    Await<override>()<suspends>:void =
        if(IsCompleted.LogicValue?):
            return
        else:
            CompletedEvent.Await()

# Spawn Insta Fix
SpawnInstaFix<public>(Func : type{_(:t)<suspends>:any}, Params : t where t:type):spawn_instant(t) =
    spawn_instant(t){Func := Func}.Spawn(Params)

# Priority Queue Node, Type Representing Data Type
priority_queue_node(t:type) := class<abstract><unique>:
    # Data to Encapsulate in Node
    Data : t
    # Higher Priority Function
    HigherPriority(Rhs : priority_queue_node(t))<transacts><decides>:void

# Priority Queue, With Data Type and Node type being a subtype of the Priority Queue Node
priority_queue(data:type, node:subtype(priority_queue_node(data))) := class:

    # Elements
    Elements : []node = array{}         

    # Get the top/highest priority Node
    Peek()<transacts><decides>:node = 
        Elements[0]

    # Pop the priority queue, removing the highest priority
    Pop()<transacts><decides>:tuple(data,priority_queue(data,node)) =
        Root := Elements[0]
        Print("Root Retrieval Checkpoint")
        var NewElements : []node = Elements
        LastElement := NewElements[NewElements.Length - 1]
        Print("Last Retrieval Checkpoint")
        set NewElements[0] = LastElement
        Print("Set Root to Last Checkpoint")
        var SiftedNodeIndex : int = 0
        LastElementRemoved := NewElements.RemoveElement[NewElements.Length - 1]
        Print("Remove Last Checkpoint")
        set NewElements = LastElementRemoved

        loop:
            var HighestPriorityIndex : int = SiftedNodeIndex
            LeftChildIndex := 2 * HighestPriorityIndex + 1
            RightChildIndex := 2 * HighestPriorityIndex + 2

            if(NewElements[LeftChildIndex].HigherPriority[NewElements[HighestPriorityIndex]]):
                set HighestPriorityIndex = LeftChildIndex
            if(NewElements[RightChildIndex].HigherPriority[NewElements[HighestPriorityIndex]]):
                set HighestPriorityIndex = RightChildIndex
            if:
                HighestPriorityIndex <> SiftedNodeIndex
                Swapped := Swap[SiftedNodeIndex, HighestPriorityIndex, NewElements]
            then:
                set NewElements = Swapped
                set SiftedNodeIndex = HighestPriorityIndex
            else:
                break

        return (Root.Data,priority_queue(data,node){Elements := NewElements})

    # Add a Node to the queue
    Enqueue(Node : node)<transacts>:priority_queue(data,node) =
        var NewElements : []node = Elements
        set NewElements += array{Node}
        var NewNodeIndex : int = NewElements.Length - 1

        loop:
            if:
                ParentIndex := Floor[ ( (NewNodeIndex - 1) * 1.0 ) / 2.0 ]
                ParentNode := NewElements[ParentIndex]
                NewElements[NewNodeIndex].HigherPriority[ParentNode]
                Swapped := Swap[NewNodeIndex, ParentIndex, NewElements]
            then:
                set NewElements = Swapped
                set NewNodeIndex = ParentIndex
            else:
                break
        
        priority_queue(data,node){Elements := NewElements}
    
    # Get the size of the priority queue
    Size():int = 
        return Elements.Length

    # If the queue is empty
    IsEmpty()<transacts><decides>:void = 
        Elements.Length <= 0

    # Swap Elements and respective indexes
    Swap(I : int, J : int, Array : []t where t:type)<transacts><decides>:[]t =
        var NewArray : []t = Array
        IthElement := NewArray[I]
        JthElement := NewArray[J]
        set NewArray[I] = JthElement
        set NewArray[J] = IthElement
        return NewArray

# SymmetricDifference(SetA : []t, SetB : []t where t:subtype(comparable)):void =
#     var Result : []t = array{}
#     for(A : SetA):
#         if()

# Intersection(SetA : []t, SetB : []t where t:subtype(comparable)):void = void

# Union
Union(SetA : []t, SetB : []t where t:subtype(comparable)):[]t = 
    MaxLength := Max(SetA.Length, SetB.Length)
    var Result : []t = array{}
    for(I := 0..MaxLength - 1):
        if(A := SetA[I], not Result.Find[A]):
            set Result += array{A}
        if(B := SetB[I], not Result.Find[B]):
            set Result += array{B}
    return Result

# Intersection
Intersection(SetA : []t, SetB : []t where t:subtype(comparable)):[]t =
    for(A : SetA, SetB.Find[A]):
        A

# Symmetric Difference
SymmetricDifference(SetA : []t, SetB : []t where t:subtype(comparable)):[]t =
    MaxLength := Max(SetA.Length, SetB.Length)
    var Result : []t = array{}
    for(I := 0..MaxLength -1):
        if(A := SetA[I], not SetB.Find[A], not Result.Find[A]):
            set Result += array{A}
        if(B := SetB[I], not SetA.Find[B], not Result.Find[B]):
            set Result += array{B}
    return Result

# Difference
Difference(SetA : []t, SetB : []t where t:subtype(comparable)):[]t =
    for(A : SetA, not SetB.Find[A]):
        A

