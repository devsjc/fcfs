// Package dummy provides a fake implementation of the QuartzAPIClient.
// All data returned is simulated on the fly and has no logical bearing between requests.
// Useful for quickly building new clients.
//
// The generated irradience data is based on the formulas and concepts from
// the lecture notes "Basics In Solar Radiation At Earth Surface" [1] and the book
// "Fundamentals Of Solar Radiation" (ISBN 978-0-367-72592-1) [2], both by Lucian Wald.
//
// Functions requiring the True Solar Time will have `tst` as a parameter.
package dummy

import (
	"math"
	"math/rand"
	"time"
)

const (
	step = time.Duration(5 * time.Minute)
)

type lnglat struct {
	lonDegs float64
	latDegs float64
}

func (l lnglat) lonRads() float64 {
	return l.lonDegs * math.Pi / 180.0
}

func (l lnglat) latRads() float64 {
	return l.latDegs * math.Pi / 180.0
}

type SolarData struct {
	timeUtc time.Time
	timeMst time.Time
	timeTst time.Time
	// eotCorrection is the equation of time in hours.
	eotCorrection time.Duration
	// angleDayRadians is the angle formed by the sun/earth line
	// on the given day of the year, and on the 1st of January of the same year.
	angleDayRadians float64
	// hourAngleRadians is the angluar arc definiting the position of the sun in it's
	// apparent path across the sky. It is zero at solar noon, negative in the morning,
	// and positive in the afternoon.
	hourAngleRadians float64
	// declinationRadians is the solar declination angle in radians.
	declinationRadians          float64
	zenithRadians               float64
	azimuthRadians              float64
	extraterrestrialIrradiation float64
	sunriseTimeTst              time.Time
	sunsetTimeTst               time.Time
	sunriseTimeMst              time.Time
	sunsetTimeMst               time.Time
	sunriseTimeUtc              time.Time
	sunsetTimeUtc               time.Time
	daylengthHours              float64
}

func determineIrradience(t time.Time, p lnglat) SolarData {
	sd := SolarData{timeUtc: t}
	yearDay := float64(t.YearDay()) + float64(t.Hour())/24.0 + float64(t.Minute())/1440.0

	// 1. Determine True Solar Time (T_TST) at the given longitude.
	//
	// True Solar Time is defined as being 12:00PM when the sun is at it's highest point in the sky.
	// This depends on the longitude, and differs from the Mean Solar Time because of the change in
	// orbital speed of the earth in its elliptical orbit around the sun. It is also referred to as
	// the Local Apparent Time [2](section 2.5,2.6).
	//
	// It is calculated by correcting the UTC time for the longitude to find the Mean Solar Time (T_MST),
	// and then correcting that for the equation of time (EOT) to find the True Solar Time (T_TST).
	sd.angleDayRadians = (2 * math.Pi / 365.2422)*yearDay
	lonCorrection := time.Duration((p.lonDegs*24.0/360.0) * float64(time.Hour))
	sd.timeMst = t.UTC().Add(lonCorrection)
	sd.eotCorrection = time.Duration((
		-0.128*math.Sin(sd.angleDayRadians-0.04887) -
		0.165*math.Sin(2*sd.angleDayRadians+0.34383)) *
		float64(time.Hour))
	sd.timeTst = sd.timeMst.Add(sd.eotCorrection)

	// 2. Determine solar declination for the given day of the year.
	//
	// Solar declination is the angle between the equatorial plane and the direction to the sun.
	// It is positive between the equinoxes of March and September, and negative elsewise [2](section 1.3).
	//
	// It is calculated via the angle formed by the sun–Earth line for a given day and that
	// for the day of the March equinox.
	num_0 := 79.3946 + (0.2422 * float64(t.Year()-1957)) - float64((t.Year()-1957)/4)
	ω_day := (2 * math.Pi / 365.2422) * (yearDay - num_0)
	sd.declinationRadians = 0.0064979 + 0.4059059*math.Sin(ω_day) + 0.0020054*math.Sin(2*ω_day) +
		-0.0029880*math.Sin(3*ω_day) + -0.0132296*math.Cos(ω_day) + 0.0063809*math.Cos(2*ω_day) + 0.0003508*math.Cos(3*ω_day)

	// 3. Determine the solar zenith and azimuthal angles at the True Solar Time.
	//
	// The solar zenithal angle is the angle formed by the direction of the sun and the local vertical.
	// The solar azimuthal angle defines the angle formed by the projection of the direction of the sun
	// on the horizontal plane and the north. [2](section 2.1).
	//
	// They are calculated based on the solar declination on the given day, and the sun's position
	// along it's apparent path across the sky (the hour angle).
	// The solar azimuth is unknown - but set to pi by convention - when the declination is 0.
	tstHour := float64(sd.timeTst.Hour()) + float64(sd.timeTst.Minute())/60.0 + float64(sd.timeTst.Second())/3600.0
	sd.hourAngleRadians = (math.Pi/12) * (tstHour-12.0)
	sd.zenithRadians = math.Acos(
		(math.Sin(p.latRads())*math.Sin(sd.declinationRadians)) +
		(math.Cos(p.latRads())*math.Cos(sd.declinationRadians)*math.Cos(sd.hourAngleRadians)),
	)
	theta_prime := (math.Sin(sd.declinationRadians)*math.Cos(p.latRads()) -
		math.Cos(sd.declinationRadians)*math.Sin(p.latRads())*math.Cos(sd.hourAngleRadians)) / math.Sin(sd.zenithRadians)
	if math.Sin(sd.hourAngleRadians) <= 0 { // Morning
		sd.azimuthRadians = math.Acos(theta_prime)
	} else { // Evening
		sd.azimuthRadians = 2*math.Pi - math.Acos(theta_prime)
	}

	// 4. Determine the local daylength and the sunrise/sunset times.
	//
	// These are calculated based on finding the hour angle at sunset,
	// when the solar declination is 0 and the solar zenithal angle is pi/2.
	var sunsetHourAngle float64
	switch {
	case p.latRads() == math.Pi/2 && sd.declinationRadians > 0:
		sunsetHourAngle = math.Pi
	case p.latRads() == math.Pi/2 && sd.declinationRadians <= 0:
		sunsetHourAngle = 0
	case p.latRads() == -math.Pi/2 && sd.declinationRadians > 0:
		sunsetHourAngle = 0
	case p.latRads() == -math.Pi/2 && sd.declinationRadians <= 0:
		sunsetHourAngle = math.Pi
	case -1*math.Tan(p.latRads())*math.Tan(sd.declinationRadians) >= 1:
		sunsetHourAngle = 0
	case -1*math.Tan(p.latRads())*math.Tan(sd.declinationRadians) <= -1:
		sunsetHourAngle = math.Pi
	default:
		// There is actually an error in my edition of the book here,
		// it should be acos, but the book has cos printed.
		sunsetHourAngle = math.Acos(-1*math.Tan(p.latRads())*math.Tan(sd.declinationRadians))
	}
	sunriseHour := 12.0 * (1.0 - (sunsetHourAngle/math.Pi))
	sunsetHour := 12.0 * (1.0 + (sunsetHourAngle/math.Pi))
	sd.sunriseTimeTst = sd.timeTst.Truncate(24 * time.Hour).Add(time.Duration(sunriseHour * float64(time.Hour)))
	sd.sunsetTimeTst = sd.timeTst.Truncate(24 * time.Hour).Add(time.Duration(sunsetHour * float64(time.Hour)))
	sd.sunriseTimeMst = sd.sunriseTimeTst.Add(-sd.eotCorrection)
	sd.sunsetTimeMst = sd.sunsetTimeTst.Add(-sd.eotCorrection)
	sd.sunriseTimeUtc = sd.sunriseTimeMst.Add(-lonCorrection)
	sd.sunsetTimeUtc = sd.sunsetTimeMst.Add(-lonCorrection)
	sd.daylengthHours = (sunsetHour - sunriseHour)

	// 5. Determine the Extraterrestrial Irradiation.
	//
	// Extraterrestrial irradiation is the irradiation on a horizontal plane
	// at the top of the atmosphere for a given True Solar Time.
	//
	// It is calculated via the solar constant E_TSI - the annual average solar irradiance
	// at the top of the atmosphere. This is modulated according to the eccentricity of the earth's orbit
	// on the given day and the solar zenithal angle at the given time. [2](section 3.2).
	ε := 0.03344 * math.Cos(sd.angleDayRadians-0.049)
	E_TSI := 1361.0
	E_0N := E_TSI * (1 + ε)
	sd.extraterrestrialIrradiation = max(E_0N * math.Cos(sd.zenithRadians), 0.0)

	return sd
}

// tst defines a type alias for time.Time to represent True Solar Time.
type tst time.Time

// toTST converts a time to the True Solar Time (T_TST) at a given longitude.
// See [2](section 2.5,2.6).
//
// True Solar Time is defined as being 12:00PM when the sun is at it's highest point in the sky.
// This depends on the longitude, and differs from the Mean Solar Time because of the change in
// orbital speed of the earth in its elliptical orbit around the sun. It is also referred to as
// the Local Apparent Time.
func toTST(t time.Time, longitude_degrees float64) tst {
	// Determine the angle swept by the earth in its orbit so far in the year
	angleDay := (2 * math.Pi / 365.2422) * float64(t.YearDay())
	// Calculate Mean Solar Time (T_MST): UTC time corrected for longitude
	// (These are the position of the tick marks on a sundial)
	lonCorrection := time.Duration(longitude_degrees*24.0/360.0) * time.Hour
	meanSolarTime := t.UTC().Add(lonCorrection)
	// Correct T_MST according to the differing speed of the earth in its elliptical orbit
	eotCorrection := time.Duration(-0.128*math.Sin(angleDay - -0.04887)-0.165*math.Sin(2*angleDay+0.34383)) * time.Hour

	// Return the True Solar Time (T_TST) as a tst type
	return tst(meanSolarTime.Add(eotCorrection))
}

// solarDeclinationRads is the angle between
// the equatorial plane and the and the direction to the sun.
// Formula taken from [2](section 1.3).
//
// Declination is positive between the equinoxes of March and September
// and negative during the other half of the year.
func solarDeclinationRads(year int, yearDay int) float64 {
	// Determine the time between 1 January 00:00 and the March equinox of input year (longitude 0°)
	num_0 := 79.3946 + (0.2422 * float64(year-1957)) - float64((year-1957)/4)
	// Determine the angle formed by the sun–Earth line for a given day,
	// and that for the day of the March equinox
	orbitAngleEquinox := (2 * math.Pi / 365.2422) * (float64(yearDay) - num_0)
	// Then determinae the solar declination angle
	d := 0.0064979
	d += 0.4059059 * math.Sin(orbitAngleEquinox)
	d += 0.0020054 * math.Sin(2*orbitAngleEquinox)
	d += -0.0029880 * math.Sin(3*orbitAngleEquinox)
	d += -0.0132296 * math.Cos(orbitAngleEquinox)
	d += 0.0063809 * math.Cos(2*orbitAngleEquinox)
	d += 0.0003508 * math.Cos(3*orbitAngleEquinox)
	return d
}

// localSunState returns various localised solar state parameters.
// Formulas taken from [2](section 2.1)
func localSunState(t time.Time, p lnglat) (zenith float64, azimuth float64, sunriseHourTST float64, sunsetHourTST float64) {
	dec := solarDeclinationRads(t.Year(), t.YearDay())
	tst := time.Time(toTST(t, p.lonDegs))

	// The hour angle measures the angular arc between
	// the plane formed by the vertical and by the longitude of the location of the observer P,
	// and the position of the sun at time t. It is zero at solar noon [2](section 2.1).
	hourAngle := (2 * math.Pi / 24) * (float64(tst.Hour()) + float64(tst.Minute())/60.0 + float64(tst.Second())/3600.0)
	// The solar zenithal angle is the angle formed by the direction of the sun and the local vertical
	solarZenith := math.Acos(math.Sin(p.latRads())*math.Sin(dec) + math.Cos(p.latRads())*math.Cos(dec)*math.Cos(hourAngle))

	// The solar azimuthal angle defines the angle formed by
	// the projection of the direction of the sun on the horizontal plane and the north
	var solarAzimuth float64
	intermediateAzimuth := (math.Sin(dec)*math.Cos(p.latRads()) - math.Cos(dec)*math.Sin(p.latRads())*math.Cos(hourAngle)) / math.Sin(solarZenith)
	switch {
	case math.Sin(hourAngle) <= 0:
		solarAzimuth = math.Acos(intermediateAzimuth)
	case math.Sin(hourAngle) > 0:
		solarAzimuth = 2*math.Pi - math.Acos(intermediateAzimuth)
	}

	// The sunset and sunrise times can be determined from the sunset hour angle,
	// which occurs when the solar zenithal angle is pi/2.
	var sunsetHourAngle float64
	switch {
	case p.latRads() == math.Pi/2 && dec > 0:
		sunsetHourAngle = math.Pi
	case p.latRads() == math.Pi/2 && dec <= 0:
		sunsetHourAngle = 0
	case p.latRads() == -math.Pi/2 && dec > 0:
		sunsetHourAngle = 0
	case p.latRads() == -math.Pi/2 && dec <= 0:
		sunsetHourAngle = math.Pi
	case -math.Tan(p.latRads())*math.Tan(dec) >= 1:
		sunsetHourAngle = 0
	case -math.Tan(p.latRads())*math.Tan(dec) <= -1:
		sunsetHourAngle = math.Pi
	default:
		sunsetHourAngle = math.Cos(-math.Tan(p.latRads()) * math.Tan(dec))
	}
	sunriseHour := 12.0 * (1.0 - sunsetHourAngle/math.Pi)
	sunsetHour := 12.0 * (1.0 + sunsetHourAngle/math.Pi)

	return solarZenith, solarAzimuth, sunriseHour, sunsetHour
}

// extraterrestrialIrradiation calculates the irradiation on a horizontal plane
// at the top of the atmosphere for a given day of the year and solar zenithal angle.
func extraterrestrialIrradiation(yearDay int, solarZenithalAngle float64) float64 {
	// First, determine the angle formed by the sun/earth line on the given day of the year
	orbitAngleRads := float64(yearDay) * 2.0 * math.Pi / 365.2422
	// Next, the correction of relative eccentricity
	ε := 0.03344 * math.Cos(orbitAngleRads-0.049)
	// Then define E_0N, the solar irradience incident on a plane
	// normal to the direction of the sun at the top of the atmosphere.
	// This requires the solar constant E_TSI: the annual average solar irradiance
	// at the top of the atmosphere in Wm^-2 [1](section 3.2)
	E_TSI := 1361.0
	E_0N := E_TSI * (1 + ε)
	// Finally, correct for the solar zenithal angle
	return E_0N * math.Cos(solarZenithalAngle)
}

type FakeYield struct {
	Yield   float64
	ErrLow  float64
	ErrHigh float64
}

// fx defines a type alias for a real mathematical function
type fx func(float64) float64

// / getWindow returns the start and end of the window for the timeseries data.
func getWindow() (time.Time, time.Time) {
	windowStart := time.Now().UTC().Add(-time.Hour * 48).Truncate(time.Hour * 24)
	windowEnd := time.Now().UTC().Add(time.Hour * 48).Truncate(time.Hour * 24)
	return windowStart, windowEnd
}

// basicYieldFunc returns a fake yield value for a given time and scale factor.
// The scale factor is used to scale the output value. A scale factor of 10000
// will result in a yield of 10kW at the peak of the curve.
// The output value is a function of the time of day and the time of year.
// The base sin function has a period of 24 hours, and peaks at 12 hours.
func basicYieldFunc(timeUnix int64, scaleFactor float64) FakeYield {
	// Convert the time to a time.Time object
	ti := time.Unix(timeUnix, 0)
	// Since the function's x values are hours, convert the time to hours, with
	// minutes being a fraction of an hour
	hour := (float64(ti.Day()) * 24.0) + float64(ti.Hour()) + (float64(ti.Minute()) / 60.0)

	// Create orbital intensity function with period 24, min/max at 0,12
	timeOfDayFunc := -1 * math.Cos(hour*math.Pi/12)
	// seasonalShift modulates the orbital intensity based on the month
	// with min/max of -0.5 and + 0.5 at the winter/summer solstices
	seasonalShift := -1 * math.Cos((math.Pi/6)*float64(ti.Month())) / 2.0

	// solarOrbitFunc ranges between -1 and +1, peaking at 12 hours, with a period of 24 hours
	// TranslateY changes the min and max to range between 1.5 and -1.5 depending on
	// the month
	solarOrbitFunc := timeOfDayFunc + seasonalShift
	// Remove negative values
	solarOrbitFunc = math.Max(solarOrbitFunc, 0.0)
	// Steepen the curve slightly. The divisor is based on the max value
	solarOrbitFunc = math.Pow(solarOrbitFunc, 4.0) / math.Pow(1.5, 4.0)

	// Instead of completely random noise, apply based on the following process:
	// * Create a base function that is the product of short and long wavelength sines
	// * The resultant function modulates with very small amplitude around 1
	noise := (math.Sin(math.Pi*hour)/20.0)*(math.Sin(hour/3.0)) + 1.0
	noise = noise * (rand.Float64()/20.0 + 0.97)

	// Create the output value from the base function, noise, and scale factor
	outputVal := solarOrbitFunc * noise * scaleFactor

	// Add some random error
	// * Error is not added if the output value is 0
	errLow, errHigh := 0.0, 0.0
	if outputVal > 0.0 {
		errLow = outputVal - (rand.Float64() * outputVal / 10.0)
		errHigh = outputVal + (rand.Float64() * outputVal / 10.0)
	}

	return FakeYield{
		Yield:   outputVal,
		ErrLow:  errLow,
		ErrHigh: errHigh,
	}
}
