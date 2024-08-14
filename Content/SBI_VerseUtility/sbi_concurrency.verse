using { /Verse.org/Concurrency }
using { /Verse.org/Simulation }

suspends_wrapper<internal>(t:type) := class:
    Callback<internal> : type{_(:t)<suspends>:void}

    Spawn<internal>(Payload:t):void=
        spawn {Callback(Payload)}

(Subscribable:subscribable(t) where t:type).SubscribeSuspends<public>(Callback:type{_(:t)<suspends>:void})<transacts>:cancelable=
    Wrapper:suspends_wrapper(t) = suspends_wrapper(t){Callback := Callback}
    Subscribable.Subscribe(Wrapper.Spawn)

event_subscriber<internal>(t:type) := class():
    Awaitable:awaitable(t)
    Cancelable:advanced_cancelable
    Callback:type{_(:t):void}

    AwaitThenSignal()<suspends>:void =
        loop:
            Payload := Awaitable.Await()
            if(Cancelable.Canceled?):
                break
            Callback(Payload)

(Awaitable:awaitable(payload) where payload:type).SubscribeData<public>(Callback:tuple(payload,data)->void, Data:data where data:type):cancelable =
    Cancelable:advanced_cancelable = advanced_cancelable{}
    spawn {AwaitData(Awaitable, Callback, Cancelable, Data)}
    Cancelable

AwaitServerTicks<public>(X : int)<suspends>:void =
    for(I := 0..X-1):
        Sleep(0.0)

(Awaitable:awaitable(t) where t:type).SubscribeEvent<public>(Callback:type{_(:t):void}):advanced_cancelable =
    Cancelable := advanced_cancelable{}
    spawn { event_subscriber(t){Awaitable := Awaitable, Cancelable := Cancelable, Callback := Callback}.AwaitThenSignal() }
    return Cancelable

advanced_cancelable<public> := class(cancelable):
    var Canceled<internal> : logic = false

    Cancel<override>()<transacts>:void =
        set Canceled = true

AwaitData<internal>(Awaitable:awaitable(payload), Callback:tuple(payload, data)->void, Cancelable:advanced_cancelable, Data:data where payload:type, data:type)<suspends>:void =
    loop:
        Payload:payload = Awaitable.Await()
        if(Cancelable.Canceled?):
            break
        Callback(Payload,Data)