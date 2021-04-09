library flutter_luna_converter;

import 'dart:math';

enum Timezone {
  chinese,
  japanese,
  korean,
  vietnamese,
}

extension ConverToInt on double {
  //floor(x) để lấy số nguyên lớn nhất không vượt quá x
  int get inFloor => floor();
}

/*
Algorithms for computing lunar calendar by timezone
 */
class FlutterLunaConverter {
  //Chuyển đổi ngày tháng năm -> số ngày Julius
  static int jdFromDate(int dd, int mm, int yy) {
    var a = 0, y = 0, m = 0, jd = 0;
    a = ((14 - mm) / 12).inFloor;
    y = yy + 4800 - a;
    m = mm + 12 * a - 3;
    jd = dd +
        ((153 * m + 2) / 5).inFloor +
        365 * y +
        (y / 4).inFloor -
        (y / 100).inFloor +
        (y / 400).inFloor -
        32045;
    if (jd < 2299161) {
      jd = dd + ((153 * m + 2) / 5).inFloor + 365 * y + (y / 4).inFloor - 32083;
    }
    return jd;
  }

  //Chuyển đổi số ngày Julius -> ngày tháng năm
  static List<int> jdToDate(int jd) {
    var result = List.filled(3, 0);
    var a = 0, b = 0, c = 0, d = 0, e = 0, m = 0, day = 0, month = 0, year = 0;
    if (jd > 2299160) {
      // After 5/10/1582, Gregorian calendar
      a = jd + 32044;
      b = ((4 * a + 3) / 146097).inFloor;
      c = a - ((b * 146097) / 4).inFloor;
    } else {
      b = 0;
      c = jd + 32082;
    }
    d = ((4 * c + 3) / 1461).inFloor;
    e = c - ((1461 * d) / 4).inFloor;
    m = ((5 * e + 2) / 153).inFloor;
    day = e - ((153 * m + 2) / 5).inFloor + 1;
    month = m + 3 - 12 * (m / 10).inFloor;
    year = b * 100 + d - 4800 + (m / 10).inFloor;

    result[0] = day;
    result[1] = month;
    result[2] = year;

    return result;
  }

  //Tính ngày Sóc thứ k kể từ điểm Sóc ngày 1/1/1900.
  //Kết quả trả về là số ngày Julius của ngày Sóc cần tìm
  static int getNewMoonDay(int k, int timeZone) {
    var T = 0.0,
        t2 = 0.0,
        t3 = 0.0,
        dr = 0.0,
        jd1 = 0.0,
        M = 0.0,
        mpr = 0.0,
        F = 0.0,
        c1 = 0.0,
        delta = 0.0,
        jdNew = 0.0;
    T = k / 1236.85; // Time in Julian centuries from 1900 January 0.5
    t2 = T * T;
    t3 = t2 * T;
    dr = pi / 180;
    jd1 = 2415020.75933 + 29.53058868 * k + 0.0001178 * t2 - 0.000000155 * t3;
    jd1 = jd1 +
        0.00033 *
            sin((166.56 + 132.87 * T - 0.009173 * t2) * dr); // Mean new moon
    M = 359.2242 +
        29.10535608 * k -
        0.0000333 * t2 -
        0.00000347 * t3; // Sun's mean anomaly
    mpr = 306.0253 +
        385.81691806 * k +
        0.0107306 * t2 +
        0.00001236 * t3; // Moon's mean anomaly
    F = 21.2964 +
        390.67050646 * k -
        0.0016528 * t2 -
        0.00000239 * t3; // Moon's argument of latitude
    c1 = (0.1734 - 0.000393 * T) * sin(M * dr) + 0.0021 * sin(2 * dr * M);
    c1 = c1 - 0.4068 * sin(mpr * dr) + 0.0161 * sin(dr * 2 * mpr);
    c1 = c1 - 0.0004 * sin(dr * 3 * mpr);
    c1 = c1 + 0.0104 * sin(dr * 2 * F) - 0.0051 * sin(dr * (M + mpr));
    c1 = c1 - 0.0074 * sin(dr * (M - mpr)) + 0.0004 * sin(dr * (2 * F + M));
    c1 = c1 - 0.0004 * sin(dr * (2 * F - M)) - 0.0006 * sin(dr * (2 * F + mpr));
    c1 = c1 +
        0.0010 * sin(dr * (2 * F - mpr)) +
        0.0005 * sin(dr * (2 * mpr + M));
    if (T < -11) {
      delta = 0.001 +
          0.000839 * T +
          0.0002261 * t2 -
          0.00000845 * t3 -
          0.000000081 * T * t3;
    } else {
      delta = -0.000278 + 0.000265 * T + 0.000262 * t2;
    }
    jdNew = jd1 + c1 - delta;
    return (jdNew + 0.5 + timeZone / 24).inFloor;
  }

  //Tính tọa độ mặt trời để biết Trung khí nào nằm trong tháng âm lịch nào,
  //Tính xem mặt trời nằm ở khoảng nào trên đường hoàng đạo
  // => vào thời điểm bắt đầu một tháng âm lịch:
  //-chia đường hoàng đạo làm 12 phần và đánh số các cung này từ 0 đến 11:
  // =>từ Xuân phân đến Cốc vũ là 0; từ Cốc vũ đến Tiểu mãn là 1;
  // =>từ Tiểu mãn đến Hạ chí là 2; v.v..
  //-cho jdn là số ngày Julius của bất kỳ một ngày,
  // =>phương pháp sau này sẽ trả lại số cung nói trên.
  static int getSunLongitude(jdn, timeZone) {
    var T = 0.0, t2 = 0.0, dr = 0.0, M = 0.0, l0 = 0.0, dl = 0.0, L = 0.0;
    T = (jdn - 2451545.5 - timeZone / 24) /
        36525; // Time in Julian centuries from 2000-01-01 12:00:00 GMT
    t2 = T * T;
    dr = pi / 180; // degree to radian
    M = 357.52910 +
        35999.05030 * T -
        0.0001559 * t2 -
        0.00000048 * T * t2; // mean anomaly, degree
    l0 = 280.46645 + 36000.76983 * T + 0.0003032 * t2; // mean longitude, degree
    dl = (1.914600 - 0.004817 * T - 0.000014 * t2) * sin(dr * M);
    dl = dl +
        (0.019993 - 0.000101 * T) * sin(dr * 2 * M) +
        0.000290 * sin(dr * 3 * M);
    L = l0 + dl; // true longitude, degree
    L = L * dr;
    L = L - pi * 2 * ((L / (pi * 2)).inFloor); // Normalize to (0, 2*PI)
    return (L / pi * 6).inFloor;
  }

  //Tìm ngày bắt đầu tháng 11 âm lịch
  //Đông chí thường nằm vào khoảng 19/12-22/12,
  // => như vậy trước hết ta tìm ngày Sóc trước ngày 31/12.
  //Nếu tháng bắt đầu vào ngày đó không chứa Đông chí
  // =>thì ta phải lùi lại 1 tháng nữa.
  static int getLunarMonth11(int yy, int timeZone) {
    var k = 0, off = 0, nm = 0, sunLong = 0;
    off = jdFromDate(31, 12, yy) - 2415021;
    k = (off / 29.530588853).inFloor;
    nm = getNewMoonDay(k, timeZone);
    sunLong = getSunLongitude(nm, timeZone); // sun longitude at local midnight
    if (sunLong >= 9) {
      nm = getNewMoonDay(k - 1, timeZone);
    }
    return nm;
  }

  //Xác định tháng nhuận
  //Nếu giữa hai tháng 11 âm lịch (tức tháng có chứa Đông chí)
  // có 13 tháng âm lịch thì năm âm lịch đó có tháng nhuận.
  static int getLeapMonthOffset(int a11, int timeZone) {
    var k = 0, last = 0, arc = 0;
    k = ((a11 - 2415021.076998695) / 29.530588853 + 0.5).inFloor;
    var i = 1; // We start with the month following lunar month 11
    arc = getSunLongitude(getNewMoonDay(k + i, timeZone), timeZone);
    do {
      last = arc;
      i++;
      arc = getSunLongitude(getNewMoonDay(k + i, timeZone), timeZone);
    } while (arc != last && i < 14);
    return i - 1;
  }

  //Get timezone by locate
  static int getTimeZoneValue(Timezone timezone) {
    switch (timezone) {
      case Timezone.chinese:
        return 8; //UTC +08
      case Timezone.japanese:
        return 9; //UTC +09
      case Timezone.korean:
        return 9; //UTC +09
      case Timezone.vietnamese:
        return 7; //UTC +07
      default:
        return 7; //UTC +07
    }
  }

  //Convert solar day to lunar day
  List<int> solarToLunar(
      int solarYear, int solarMonth, int solarDay, Timezone timezone) {
    var result = List<int>.filled(3, 0);

    var utcValue = getTimeZoneValue(timezone);
    var k = 0,
        dayNumber = 0,
        monthStart = 0,
        a11 = 0,
        b11 = 0,
        lunarDay = 0,
        lunarMonth = 0,
        lunarYear = 0;
    // lunarLeap = 0;
    dayNumber = jdFromDate(solarDay, solarMonth, solarYear);
    k = ((dayNumber - 2415021.076998695) / 29.530588853).inFloor;
    monthStart = getNewMoonDay(k + 1, utcValue);
    if (monthStart > dayNumber) {
      monthStart = getNewMoonDay(k, utcValue);
    }
    a11 = getLunarMonth11(solarYear, utcValue);
    b11 = a11;
    if (a11 >= monthStart) {
      lunarYear = solarYear;
      a11 = getLunarMonth11(solarYear - 1, utcValue);
    } else {
      lunarYear = solarYear + 1;
      b11 = getLunarMonth11(solarYear + 1, utcValue);
    }
    lunarDay = dayNumber - monthStart + 1;
    var diff = ((monthStart - a11) / 29).inFloor;
    // lunarLeap = 0;
    lunarMonth = diff + 11;
    if (b11 - a11 > 365) {
      var leapMonthDiff = getLeapMonthOffset(a11, utcValue);
      if (diff >= leapMonthDiff) {
        lunarMonth = diff + 10;
        // if (diff == leapMonthDiff) {
        //   lunarLeap = 1;
        // }
      }
    }
    // print(lunarLeap);
    if (lunarMonth > 12) {
      lunarMonth = lunarMonth - 12;
    }
    if (lunarMonth >= 11 && diff < 4) {
      lunarYear -= 1;
    }

    result[0] = lunarDay;
    result[1] = lunarMonth;
    result[2] = lunarYear;

    return result;
  }

  //Convert lunar day to solar day
  List<int> lunarToSolar(int lunarYear, int lunarMonth, int lunarDay,
      int lunarLeap, Timezone timezone) {
    var result = List<int>.filled(3, 0);
    var utcValue = getTimeZoneValue(timezone);
    var k = 0,
        a11 = 0,
        b11 = 0,
        off = 0,
        leapOff = 0,
        leapMonth = 0,
        monthStart = 0;
    if (lunarMonth < 11) {
      a11 = getLunarMonth11(lunarYear - 1, utcValue);
      b11 = getLunarMonth11(lunarYear, utcValue);
    } else {
      a11 = getLunarMonth11(lunarYear, utcValue);
      b11 = getLunarMonth11(lunarYear + 1, utcValue);
    }
    off = lunarMonth - 11;
    if (off < 0) {
      off += 12;
    }
    if (b11 - a11 > 365) {
      leapOff = getLeapMonthOffset(a11, utcValue);
      leapMonth = leapOff - 2;
      if (leapMonth < 0) {
        leapMonth += 12;
      }
      if (lunarLeap != 0 && lunarMonth != leapMonth) {
        result[0] = 0;
        result[1] = 0;
        result[2] = 0;
      } else if (lunarLeap != 0 || off >= leapOff) {
        off += 1;
      }
    }
    k = (0.5 + (a11 - 2415021.076998695) / 29.530588853).inFloor;
    monthStart = getNewMoonDay(k + off, utcValue);
    return jdToDate(monthStart + lunarDay - 1);
  }
}
