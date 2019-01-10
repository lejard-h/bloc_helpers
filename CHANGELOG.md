## 0.2.0

- ***Breaking Change***
    use contructor for unique selector
        SelectorBloc(); // not unique
        SelectorBloc.unique();

- `AsyncTaskBloc` and `AsyncCachedTaskBloc`

- ***Deprecated***
    + `requestSink` renamed to `callSink`
    + `onLoading` renamed to `onRunning`
    + `onRequest` renamed to `onResult`
    + `onRequest` renamed to `onStart`
    + `cachedResponse` renamed to `cachedResult`
    + `updateCachedResponseSink` to `updateCachedResultSink`

## 0.1.1

- fix selector

## 0.1.0

- Observable instead of Stream
- use ValueObservable
- dispose function is now async

## 0.0.6

- addd disposed check before addError

## 0.0.5

- cleanup abd better README

## 0.0.4

- protected request method

## 0.0.3

- fix cached response sink

## 0.0.2

- add onRequest stream

## 0.0.1

- first version