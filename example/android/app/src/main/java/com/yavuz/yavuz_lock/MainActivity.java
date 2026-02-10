package com.yavuz.yavuz_lock;

import android.os.Bundle;
import androidx.activity.EdgeToEdge;
import com.ttlock.ttlock_flutter.TtlockFlutterPlugin;

import io.flutter.embedding.android.FlutterFragmentActivity;

public class MainActivity extends FlutterFragmentActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        EdgeToEdge.enable(this);
        super.onCreate(savedInstanceState);
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (getFlutterEngine() != null) {
            TtlockFlutterPlugin ttlockflutterpluginPlugin = (TtlockFlutterPlugin) getFlutterEngine().getPlugins()
                    .get(TtlockFlutterPlugin.class);
            if (ttlockflutterpluginPlugin != null) {
                ttlockflutterpluginPlugin.onRequestPermissionsResult(requestCode, permissions, grantResults);
            }
        }
    }
}
