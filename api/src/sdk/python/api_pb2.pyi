from google.protobuf.internal import containers as _containers
from google.protobuf import descriptor as _descriptor
from google.protobuf import message as _message
from typing import ClassVar as _ClassVar, Iterable as _Iterable, Mapping as _Mapping, Optional as _Optional, Union as _Union

DESCRIPTOR: _descriptor.FileDescriptor

class GetPredictedTimeseriesRequest(_message.Message):
    __slots__ = ("location_ids",)
    LOCATION_IDS_FIELD_NUMBER: _ClassVar[int]
    location_ids: _containers.RepeatedScalarFieldContainer[str]
    def __init__(self, location_ids: _Optional[_Iterable[str]] = ...) -> None: ...

class GetPredictedTimeseriesResponse(_message.Message):
    __slots__ = ("location_id", "yields")
    LOCATION_ID_FIELD_NUMBER: _ClassVar[int]
    YIELDS_FIELD_NUMBER: _ClassVar[int]
    location_id: str
    yields: _containers.RepeatedCompositeFieldContainer[PredictedYield]
    def __init__(self, location_id: _Optional[str] = ..., yields: _Optional[_Iterable[_Union[PredictedYield, _Mapping]]] = ...) -> None: ...

class PredictedYield(_message.Message):
    __slots__ = ("yield_kw", "timestamp_unix", "uncertainty")
    YIELD_KW_FIELD_NUMBER: _ClassVar[int]
    TIMESTAMP_UNIX_FIELD_NUMBER: _ClassVar[int]
    UNCERTAINTY_FIELD_NUMBER: _ClassVar[int]
    yield_kw: int
    timestamp_unix: int
    uncertainty: PredictedYieldUncertainty
    def __init__(self, yield_kw: _Optional[int] = ..., timestamp_unix: _Optional[int] = ..., uncertainty: _Optional[_Union[PredictedYieldUncertainty, _Mapping]] = ...) -> None: ...

class PredictedYieldUncertainty(_message.Message):
    __slots__ = ("lower_kw", "upper_kw")
    LOWER_KW_FIELD_NUMBER: _ClassVar[int]
    UPPER_KW_FIELD_NUMBER: _ClassVar[int]
    lower_kw: int
    upper_kw: int
    def __init__(self, lower_kw: _Optional[int] = ..., upper_kw: _Optional[int] = ...) -> None: ...

class GetActualTimeseriesRequest(_message.Message):
    __slots__ = ("location_ids",)
    LOCATION_IDS_FIELD_NUMBER: _ClassVar[int]
    location_ids: _containers.RepeatedScalarFieldContainer[str]
    def __init__(self, location_ids: _Optional[_Iterable[str]] = ...) -> None: ...

class GetActualTimeseriesResponse(_message.Message):
    __slots__ = ("location_id", "yields")
    LOCATION_ID_FIELD_NUMBER: _ClassVar[int]
    YIELDS_FIELD_NUMBER: _ClassVar[int]
    location_id: str
    yields: _containers.RepeatedCompositeFieldContainer[ActualYield]
    def __init__(self, location_id: _Optional[str] = ..., yields: _Optional[_Iterable[_Union[ActualYield, _Mapping]]] = ...) -> None: ...

class ActualYield(_message.Message):
    __slots__ = ("yield_kw", "timestamp_unix")
    YIELD_KW_FIELD_NUMBER: _ClassVar[int]
    TIMESTAMP_UNIX_FIELD_NUMBER: _ClassVar[int]
    yield_kw: int
    timestamp_unix: int
    def __init__(self, yield_kw: _Optional[int] = ..., timestamp_unix: _Optional[int] = ...) -> None: ...

class GetPredictedCrossSectionRequest(_message.Message):
    __slots__ = ("location_ids", "timestamp_unix")
    LOCATION_IDS_FIELD_NUMBER: _ClassVar[int]
    TIMESTAMP_UNIX_FIELD_NUMBER: _ClassVar[int]
    location_ids: _containers.RepeatedScalarFieldContainer[str]
    timestamp_unix: int
    def __init__(self, location_ids: _Optional[_Iterable[str]] = ..., timestamp_unix: _Optional[int] = ...) -> None: ...

class GetPredictedCrossSectionResponse(_message.Message):
    __slots__ = ("timestamp_unix", "yields")
    TIMESTAMP_UNIX_FIELD_NUMBER: _ClassVar[int]
    YIELDS_FIELD_NUMBER: _ClassVar[int]
    timestamp_unix: int
    yields: _containers.RepeatedCompositeFieldContainer[PredictedYieldAtLocation]
    def __init__(self, timestamp_unix: _Optional[int] = ..., yields: _Optional[_Iterable[_Union[PredictedYieldAtLocation, _Mapping]]] = ...) -> None: ...

class PredictedYieldAtLocation(_message.Message):
    __slots__ = ("location_id", "yield_kw", "uncertainty")
    LOCATION_ID_FIELD_NUMBER: _ClassVar[int]
    YIELD_KW_FIELD_NUMBER: _ClassVar[int]
    UNCERTAINTY_FIELD_NUMBER: _ClassVar[int]
    location_id: str
    yield_kw: int
    uncertainty: PredictedYieldUncertainty
    def __init__(self, location_id: _Optional[str] = ..., yield_kw: _Optional[int] = ..., uncertainty: _Optional[_Union[PredictedYieldUncertainty, _Mapping]] = ...) -> None: ...

class GetActualCrossSectionRequest(_message.Message):
    __slots__ = ("location_ids", "timestamp_unix")
    LOCATION_IDS_FIELD_NUMBER: _ClassVar[int]
    TIMESTAMP_UNIX_FIELD_NUMBER: _ClassVar[int]
    location_ids: _containers.RepeatedScalarFieldContainer[str]
    timestamp_unix: int
    def __init__(self, location_ids: _Optional[_Iterable[str]] = ..., timestamp_unix: _Optional[int] = ...) -> None: ...

class GetActualCrossSectionResponse(_message.Message):
    __slots__ = ("timestamp_unix", "yields")
    TIMESTAMP_UNIX_FIELD_NUMBER: _ClassVar[int]
    YIELDS_FIELD_NUMBER: _ClassVar[int]
    timestamp_unix: int
    yields: _containers.RepeatedCompositeFieldContainer[ActualYieldAtLocation]
    def __init__(self, timestamp_unix: _Optional[int] = ..., yields: _Optional[_Iterable[_Union[ActualYieldAtLocation, _Mapping]]] = ...) -> None: ...

class ActualYieldAtLocation(_message.Message):
    __slots__ = ("location_id", "yield_kw")
    LOCATION_ID_FIELD_NUMBER: _ClassVar[int]
    YIELD_KW_FIELD_NUMBER: _ClassVar[int]
    location_id: str
    yield_kw: int
    def __init__(self, location_id: _Optional[str] = ..., yield_kw: _Optional[int] = ...) -> None: ...

class CreateSiteRequest(_message.Message):
    __slots__ = ("name", "latitude", "longitude", "capacity_kw", "metadata")
    NAME_FIELD_NUMBER: _ClassVar[int]
    LATITUDE_FIELD_NUMBER: _ClassVar[int]
    LONGITUDE_FIELD_NUMBER: _ClassVar[int]
    CAPACITY_KW_FIELD_NUMBER: _ClassVar[int]
    METADATA_FIELD_NUMBER: _ClassVar[int]
    name: str
    latitude: float
    longitude: float
    capacity_kw: int
    metadata: str
    def __init__(self, name: _Optional[str] = ..., latitude: _Optional[float] = ..., longitude: _Optional[float] = ..., capacity_kw: _Optional[int] = ..., metadata: _Optional[str] = ...) -> None: ...

class CreateGspRequest(_message.Message):
    __slots__ = ("name", "geometry", "capacity_kw", "metadata")
    NAME_FIELD_NUMBER: _ClassVar[int]
    GEOMETRY_FIELD_NUMBER: _ClassVar[int]
    CAPACITY_KW_FIELD_NUMBER: _ClassVar[int]
    METADATA_FIELD_NUMBER: _ClassVar[int]
    name: str
    geometry: str
    capacity_kw: int
    metadata: str
    def __init__(self, name: _Optional[str] = ..., geometry: _Optional[str] = ..., capacity_kw: _Optional[int] = ..., metadata: _Optional[str] = ...) -> None: ...

class CreateLocationResponse(_message.Message):
    __slots__ = ("location_id",)
    LOCATION_ID_FIELD_NUMBER: _ClassVar[int]
    location_id: str
    def __init__(self, location_id: _Optional[str] = ...) -> None: ...
