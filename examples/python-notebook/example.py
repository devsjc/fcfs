# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "betterproto==2.0.0b7",
#     "grpclib"
# ]
# ///

from grpclib.client import Channel
from ocf import dp
import betterproto.grpc
import asyncio
import datetime as dt

async def main() -> None:
    channel = Channel(host="localhost", port=50051)
    client = dp.DataPlatformServiceStub(channel)

    request = dp.GetLatestPredictionsRequest(
        location_id=1,
        energy_source=dp.EnergySource.SOLAR,
        pivot_timestamp_unix=dt.datetime.now().replace(minute=0, second=0, microsecond=0, tzinfo=dt.UTC),
        model=dp.Model(
            model_name="test_model",
            model_version="v10",
        ),
    )
    response = await client.get_latest_predictions(request)
    print(response)

    request2 = dp.GetPredictedTimeseriesRequest(
        location_id=1,
        energy_source=dp.EnergySource.SOLAR,
        horizon_mins=0,
        time_window=dp.TimeWindow(
            start_timestamp_unix=dt.datetime.now().replace(tzinfo=dt.UTC) - dt.timedelta(hours=48),
            end_timestamp_unix=dt.datetime.now().replace(tzinfo=dt.UTC),
        ),
        model=dp.Model(
            model_name="test_model",
            model_version="v10",
        ),
    )
    response2 = await client.get_predicted_timeseries(request2)
    print(response2)

    request3 = dp.GetWeekAverageDeltasRequest(
        location_id=1,
        energy_source=dp.EnergySource.SOLAR,
        model=dp.Model(
            model_name="test_model",
            model_version="v10",
        ),
        observer_name="test_observer",
        pivot_time=dt.datetime.now().replace(minute=0, second=0, microsecond=0, tzinfo=dt.UTC),
    )
    response3 = await client.get_week_average_deltas(request3)

    channel.close()

if __name__ == "__main__":
    asyncio.run(main())

