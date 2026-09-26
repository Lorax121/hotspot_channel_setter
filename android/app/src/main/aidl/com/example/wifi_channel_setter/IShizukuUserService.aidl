package com.example.wifi_channel_setter;

import android.os.Bundle;

interface IShizukuUserService {
    void destroy() = 16777114;

    Bundle getIwList(long timeoutMillis) = 1;

    Bundle getAllowedChannels(long timeoutMillis) = 3;

    Bundle getSoftApCapability(long timeoutMillis) = 6;

    Bundle getSoftApState(long timeoutMillis) = 7;

    Bundle resetChannel(long timeoutMillis) = 8;

    Bundle setChannel(int frequency, long timeoutMillis, boolean persistent) = 2;
}
