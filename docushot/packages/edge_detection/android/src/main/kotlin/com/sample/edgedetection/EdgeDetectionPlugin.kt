package com.sample.edgedetection

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.exifinterface.media.ExifInterface
import com.sample.edgedetection.scan.ScanActivity
import com.sample.edgedetection.processor.processPicture
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import org.opencv.android.OpenCVLoader
import org.opencv.core.Core
import org.opencv.core.Mat
import org.opencv.imgcodecs.Imgcodecs

class EdgeDetectionPlugin : FlutterPlugin, ActivityAware {
    private var handler: EdgeDetectionHandler? = null

    override fun onAttachedToEngine(binding: FlutterPluginBinding) {
        handler = EdgeDetectionHandler()
        val channel = MethodChannel(
            binding.binaryMessenger, "edge_detection"
        )
        channel.setMethodCallHandler(handler)
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {}

    override fun onAttachedToActivity(activityPluginBinding: ActivityPluginBinding) {
        handler?.setActivityPluginBinding(activityPluginBinding)
    }

    override fun onDetachedFromActivityForConfigChanges() {}
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {}
    override fun onDetachedFromActivity() {}
}

class EdgeDetectionHandler : MethodCallHandler, PluginRegistry.ActivityResultListener {
    private var activityPluginBinding: ActivityPluginBinding? = null
    private var result: Result? = null
    private var methodCall: MethodCall? = null

    companion object {
        const val INITIAL_BUNDLE = "initial_bundle"
        const val FROM_GALLERY = "from_gallery"
        const val SAVE_TO = "save_to"
        const val CAN_USE_GALLERY = "can_use_gallery"
        const val SCAN_TITLE = "scan_title"
        const val CROP_TITLE = "crop_title"
        const val CROP_BLACK_WHITE_TITLE = "crop_black_white_title"
        const val CROP_RESET_TITLE = "crop_reset_title"
    }

    fun setActivityPluginBinding(activityPluginBinding: ActivityPluginBinding) {
        activityPluginBinding.addActivityResultListener(this)
        this.activityPluginBinding = activityPluginBinding
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "edge_detect" || call.method == "edge_detect_gallery") {
            if (getActivity() == null) {
                result.error("no_activity", "edge_detection plugin requires a foreground activity.", null)
                return
            }
        }

        when (call.method) {
            "edge_detect" -> openCameraActivity(call, result)
            "edge_detect_gallery" -> openGalleryActivity(call, result)
            "detect_edges_file" -> detectEdgesFile(call, result)
            else -> result.notImplemented()
        }
    }

    private fun detectEdgesFile(call: MethodCall, result: Result) {
        val filePath = call.argument<String>("save_to") // We use save_to as 'path' input
        if (filePath == null) {
            result.error("invalid_arg", "File path missing", null)
            return
        }

        Thread {
            try {
                if (!OpenCVLoader.initDebug()) {
                    Handler(Looper.getMainLooper()).post {
                        result.error("opencv_error", "OpenCV init failed", null)
                    }
                    return@Thread
                }

                // Handle Rotation
                val exif = ExifInterface(filePath)
                val orientation = exif.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_UNDEFINED)
                var rotation = -1
                when (orientation) {
                    ExifInterface.ORIENTATION_ROTATE_90 -> rotation = Core.ROTATE_90_CLOCKWISE
                    ExifInterface.ORIENTATION_ROTATE_180 -> rotation = Core.ROTATE_180
                    ExifInterface.ORIENTATION_ROTATE_270 -> rotation = Core.ROTATE_90_COUNTERCLOCKWISE
                }

                var mat: Mat = Imgcodecs.imread(filePath)
                
                if (rotation > -1) {
                    val dest = Mat()
                    Core.rotate(mat, dest, rotation)
                    mat.release()
                    mat = dest
                }

                val corners = processPicture(mat)
                mat.release()

                val resultMap = ArrayList<Map<String, Double>>()
                if (corners != null && corners.corners.size == 4) {
                    for (p in corners.corners) {
                        if (p != null) {
                            resultMap.add(mapOf("x" to p.x, "y" to p.y))
                        } else {
                             resultMap.add(mapOf("x" to 0.0, "y" to 0.0))
                        }
                    }
                    Handler(Looper.getMainLooper()).post {
                        result.success(resultMap)
                    }
                } else {
                    Handler(Looper.getMainLooper()).post {
                        result.success(null)
                    }
                }

            } catch (e: Exception) {
                Handler(Looper.getMainLooper()).post {
                    result.error("processing_error", e.toString(), null)
                }
            }
        }.start()
    }

    private fun getActivity(): Activity? {
        return activityPluginBinding?.activity
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == REQUEST_CODE) {
            when (resultCode) {
                Activity.RESULT_OK -> finishWithSuccess(true)
                Activity.RESULT_CANCELED -> finishWithSuccess(false)
                ERROR_CODE -> finishWithError(ERROR_CODE.toString(), data?.getStringExtra("RESULT") ?: "ERROR")
            }
            return true
        }
        return false
    }

    private fun openCameraActivity(call: MethodCall, result: Result) {
        if (!setPendingMethodCallAndResult(call, result)) {
            finishWithAlreadyActiveError()
            return
        }
        val initialIntent = Intent(getActivity()?.applicationContext, ScanActivity::class.java)
        val bundle = Bundle()
        bundle.putString(SAVE_TO, call.argument<String>(SAVE_TO) as String)
        bundle.putString(SCAN_TITLE, call.argument<String>(SCAN_TITLE) as String)
        bundle.putString(CROP_TITLE, call.argument<String>(CROP_TITLE) as String)
        bundle.putString(CROP_BLACK_WHITE_TITLE, call.argument<String>(CROP_BLACK_WHITE_TITLE) as String)
        bundle.putString(CROP_RESET_TITLE, call.argument<String>(CROP_RESET_TITLE) as String)
        bundle.putBoolean(CAN_USE_GALLERY, call.argument<Boolean>(CAN_USE_GALLERY) as Boolean)
        initialIntent.putExtra(INITIAL_BUNDLE, bundle)
        getActivity()?.startActivityForResult(initialIntent, REQUEST_CODE)
    }

    private fun openGalleryActivity(call: MethodCall, result: Result) {
        if (!setPendingMethodCallAndResult(call, result)) {
            finishWithAlreadyActiveError()
            return
        }
        val initialIntent = Intent(getActivity()?.applicationContext, ScanActivity::class.java)
        val bundle = Bundle()
        bundle.putString(SAVE_TO, call.argument<String>(SAVE_TO) as String)
        bundle.putString(CROP_TITLE, call.argument<String>(CROP_TITLE) as String)
        bundle.putString(CROP_BLACK_WHITE_TITLE, call.argument<String>(CROP_BLACK_WHITE_TITLE) as String )
        bundle.putString(CROP_RESET_TITLE, call.argument<String>(CROP_RESET_TITLE) as String)
        bundle.putBoolean(FROM_GALLERY, call.argument<Boolean>(FROM_GALLERY) as Boolean)
        initialIntent.putExtra(INITIAL_BUNDLE, bundle)
        getActivity()?.startActivityForResult(initialIntent, REQUEST_CODE)
    }

    private fun setPendingMethodCallAndResult(methodCall: MethodCall, result: Result): Boolean {
        if (this.result != null) return false
        this.methodCall = methodCall
        this.result = result
        return true
    }

    private fun finishWithAlreadyActiveError() {
        finishWithError("already_active", "Edge detection is already active")
    }

    private fun finishWithError(errorCode: String, errorMessage: String) {
        result?.error(errorCode, errorMessage, null)
        clearMethodCallAndResult()
    }

    private fun finishWithSuccess(res: Boolean) {
        result?.success(res)
        clearMethodCallAndResult()
    }

    private fun clearMethodCallAndResult() {
        methodCall = null
        result = null
    }
}
