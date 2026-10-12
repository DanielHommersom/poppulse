// PopPulseNative for Android (US-42): the same singleton name and methods as the
// iOS plugin, so autoload/platform.gd needs no Android-specific branches.
// Godot Android plugin v2 (Godot 4.2+). Build: see docs/build-android.md.
package com.digitaldiamonds.poppulse

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.provider.Settings
import androidx.core.content.FileProvider
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.UsedByGodot
import java.io.File

class PopPulseNative(godot: Godot) : GodotPlugin(godot) {
    override fun getPluginName() = "PopPulseNative"

    private val vibrator: Vibrator? by lazy {
        activity?.getSystemService(Vibrator::class.java)
    }

    @UsedByGodot
    fun prepare_haptics() {}

    /** 0 light, 1 medium, 2 heavy, 3 error — predefined effects feel crisp and never queue. */
    @UsedByGodot
    fun haptic(kind: Int) {
        val v = vibrator ?: return
        if (Build.VERSION.SDK_INT >= 29) {
            val effect = when (kind) {
                0 -> VibrationEffect.EFFECT_TICK
                1 -> VibrationEffect.EFFECT_CLICK
                2 -> VibrationEffect.EFFECT_HEAVY_CLICK
                else -> VibrationEffect.EFFECT_DOUBLE_CLICK
            }
            v.vibrate(VibrationEffect.createPredefined(effect))
        } else {
            val ms = longArrayOf(10, 18, 30, 45)[kind.coerceIn(0, 3)]
            v.vibrate(VibrationEffect.createOneShot(ms, VibrationEffect.DEFAULT_AMPLITUDE))
        }
    }

    /** Native share sheet with the PNG from user:// (exposed through a FileProvider). */
    @UsedByGodot
    fun share_image(pngPath: String, text: String) {
        val act = activity ?: return
        val file = File(pngPath)
        val uri = FileProvider.getUriForFile(act, act.packageName + ".poppulse.share", file)
        val send = Intent(Intent.ACTION_SEND).apply {
            type = "image/png"
            putExtra(Intent.EXTRA_STREAM, uri)
            putExtra(Intent.EXTRA_TEXT, text)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        act.runOnUiThread { act.startActivity(Intent.createChooser(send, null)) }
    }

    /** "Remove animations" in Android accessibility settings. */
    @UsedByGodot
    fun system_reduce_motion(): Boolean {
        val act = activity ?: return false
        val scale = Settings.Global.getFloat(act.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f)
        return scale == 0f
    }

    @UsedByGodot
    fun open_url(url: String) {
        activity?.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
    }

    // No ATT on Android: report "authorized" so consent alone decides.
    @UsedByGodot
    fun request_tracking_authorization() {}

    @UsedByGodot
    fun tracking_status(): Int = 3
}
