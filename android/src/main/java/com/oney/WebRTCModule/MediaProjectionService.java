package com.oney.WebRTCModule;


import android.app.Service;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ServiceInfo;
import android.os.Build;
import android.os.IBinder;
import android.util.Log;
import android.media.projection.MediaProjection;
import android.media.projection.MediaProjectionManager;
import android.app.Activity;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;

import androidx.annotation.RequiresApi;
import androidx.core.app.NotificationCompat;

import java.util.Random;

import org.webrtc.audio.WebRtcAudioRecord;
import org.webrtc.callback.CallbackClearSession;
import org.webrtc.callback.CallbackManager;

import com.facebook.react.bridge.ReactApplicationContext;

/**
 * This class implements an Android {@link Service}, a foreground one specifically, and it's
 * responsible for presenting an ongoing notification when a conference is in progress.
 * The service will help keep the app running while in the background.
 * <p>
 * See: https://developer.android.com/guide/components/services
 */
public class MediaProjectionService extends Service {
    public static final String EXTRA_MEDIA_PROJECTION_DATA = "mediaProjectionData";
    static final int NOTIFICATION_ID = new Random().nextInt(99999) + 10000;
    private static final String TAG = "Service_MPJ";
    private static MediaProjectionServiceListener listener;
    private static StopServiceListener serviceListener;
    private final String TITLE_NOTIFI = "Beings Screen Capturer";
    private final String CONTENT_NOTIFI = TITLE_NOTIFI + " is running";
    public MediaProjection mediaProjection;
    private MediaProjectionManager mediaProjectionManager;

    public static void setListener(MediaProjectionServiceListener listener) {
        MediaProjectionService.listener = listener;
    }

    public static void setListener(StopServiceListener listener) {
        MediaProjectionService.serviceListener = listener;
    }

    public static void assignAbortService(ReactApplicationContext reactContext) {
        CallbackClearSession.assignCallback(
                new CallbackClearSession.Callback() {
                    @Override
                    public void execute() {
                        MediaProjectionService.abort(reactContext.getApplicationContext());
                        serviceListener.serviceIsStop();
                    }

                    @Override
                    public String getKey() {
                        return "STOP_SERVICE_MEDIA_PROJECTION";
                    }
                });
    }

    public static void launch(Context context, Intent data) {
        if (!WebRTCModuleOptions.getInstance().enableMediaProjectionService) {
            return;
        }

        Intent serviceIntent = new Intent(context, MediaProjectionService.class);
        serviceIntent.putExtra(EXTRA_MEDIA_PROJECTION_DATA, data);
        ComponentName componentName;

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                componentName = context.startForegroundService(serviceIntent);
            } else {
                componentName = context.startService(serviceIntent);
            }
        } catch (RuntimeException e) {
            // Avoid crashing due to ForegroundServiceStartNotAllowedException (API level 31).
            // See: https://developer.android.com/guide/components/foreground-services#background-start-restrictions
            Log.w(TAG, "Media projection service not started", e);
            return;
        }

        if (componentName == null) {
            Log.w(TAG, "Media projection service not started");
        } else {
            Log.i(TAG, "Media projection service started");
        }
    }

    public static void abort(Context context) {
        if (!WebRTCModuleOptions.getInstance().enableMediaProjectionService) {

            return;
        }
        Intent intent = new Intent(context, MediaProjectionService.class);
        context.stopService(intent);
    }


    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    private void customNotificationMethod(Context context) {

        String CHANEL_ID = Integer.toString(NOTIFICATION_ID);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(CHANEL_ID, CHANEL_ID, NotificationManager.IMPORTANCE_DEFAULT);

            getSystemService(NotificationManager.class).createNotificationChannel(channel);
            Notification.Builder notification = new Notification.Builder(this, CHANEL_ID)
                    .setSmallIcon(android.R.drawable.ic_dialog_info)
                    .setContentText(CONTENT_NOTIFI)
                    .setContentTitle(TITLE_NOTIFI);

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(NOTIFICATION_ID, notification.build(), ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION);
            } else {
                startForeground(NOTIFICATION_ID, notification.build());

            }
        } else {
            NotificationCompat.Builder builder = new NotificationCompat.Builder(context)
                    .setSmallIcon(android.R.drawable.ic_dialog_info)
                    .setContentTitle(TITLE_NOTIFI)
                    .setContentText(CONTENT_NOTIFI)
                    .setPriority(NotificationCompat.PRIORITY_DEFAULT);
            startForeground(NOTIFICATION_ID, builder.build());
        }
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {

        Intent data = intent.getParcelableExtra(EXTRA_MEDIA_PROJECTION_DATA);
        mediaProjectionManager = (MediaProjectionManager) getApplicationContext().getSystemService(MEDIA_PROJECTION_SERVICE);
        assert data != null;
        mediaProjection = mediaProjectionManager.getMediaProjection(Activity.RESULT_OK, data);
        listener.mediaProjectionOnSuccess(mediaProjection);
        customNotificationMethod(this);

        return START_NOT_STICKY;
    }


    public interface MediaProjectionServiceListener {
        void mediaProjectionOnSuccess(MediaProjection mediaProjection);
    }

    public interface StopServiceListener {
        void serviceIsStop();
    }
}
