package com.toadhealth.wear

import android.animation.TimeAnimator
import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.util.AttributeSet
import android.view.View
import kotlin.math.min
import kotlin.math.sin

/**
 * The hand-drawn toad, drawn at runtime on the wrist.
 *
 * Same spirit as the phone-side `ToadPainter` (lib/toad_painter.dart):
 * ink outlines, swamp-green body, cream belly, coral cheeks - but this one
 * is plain Canvas/Paint Kotlin, because the companion module is a tiny
 * native app with no Flutter engine on board.
 *
 * Poses: idle breathing (the throat pulses) plus a short hop whenever the
 * pond sends news from the phone.
 */
class ToadView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
) : View(context, attrs) {

    private val bodyPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val bellyPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val inkPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        color = 0xFF2B2B20.toInt()
    }
    private val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val cheekPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val spotPaint = Paint(Paint.ANTI_ALIAS_FLAG)

    private val animator = TimeAnimator()

    private var phase = 0f
    private var celebrateUntil = 0L
    private var blinkUntil = 0L
    private var nextBlink = 0L
    var ambient = false
        set(value) {
            field = value
            if (value) animator.cancel() else startAnimation()
        }

    init {
        animator.setTimeListener { _, _, delta ->
            phase += delta / 1000f
            if (System.currentTimeMillis() >= nextBlink) {
                blinkUntil = System.currentTimeMillis() + 140
                nextBlink = System.currentTimeMillis() + 2100 + (phase * 997 % 1600).toLong()
            }
            invalidate()
        }
    }

    /** A quick happy hop - called when fresh pond news arrives. */
    fun celebrate() {
        if (ambient) return
        celebrateUntil = System.currentTimeMillis() + 780
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        if (!ambient) startAnimation()
    }

    override fun onDetachedFromWindow() {
        animator.cancel()
        super.onDetachedFromWindow()
    }

    private fun startAnimation() {
        if (!animator.isRunning) animator.start()
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val w = width.toFloat()
        val h = height.toFloat()
        if (w <= 0 || h <= 0) return

        bodyPaint.color = 0xFF5F9C3F.toInt()
        bellyPaint.color = 0xFFF6F1E0.toInt()
        cheekPaint.color = 0xFFE2694E.toInt()
        spotPaint.color = 0xFF3B6B2B.toInt()
        inkPaint.strokeWidth = min(w, h) / 42f

        val now = System.currentTimeMillis()
        var celebrating = now < celebrateUntil
        if (ambient) celebrating = false

        // Idle breathing: the throat gently pulses; ambient freezes it.
        val breathe = if (ambient) 0f else sin(phase * 2.4f) * 0.045f
        val hop = if (celebrating) {
            val t = 1f - (celebrateUntil - now) / 780f
            -sin(min(t, 1f) * Math.PI).toFloat() * h * 0.16f
        } else {
            0f
        }

        val cx = w / 2f
        val cy = h * 0.58f + hop
        val rx = w * 0.36f
        val ry = h * 0.26f * (1f + breathe)

        val body = RectF(cx - rx, cy - ry, cx + rx, cy + ry)

        // Back feet peeking from under the body.
        fillPaint.color = 0xFF3B6B2B.toInt()
        canvas.drawOval(cx - rx * 0.82f, cy + ry * 0.72f, cx - rx * 0.42f, cy + ry * 1.02f, fillPaint)
        canvas.drawOval(cx + rx * 0.42f, cy + ry * 0.72f, cx + rx * 0.82f, cy + ry * 1.02f, fillPaint)

        // Body.
        canvas.drawOval(body, bodyPaint)
        canvas.drawOval(body, inkPaint)

        // Belly.
        val belly = RectF(
            cx - rx * 0.62f, cy - ry * 0.10f,
            cx + rx * 0.62f, cy + ry * 0.88f,
        )
        canvas.drawOval(belly, bellyPaint)

        // Spots.
        canvas.drawCircle(cx - rx * 0.52f, cy - ry * 0.30f, rx * 0.10f, spotPaint)
        canvas.drawCircle(cx + rx * 0.44f, cy - ry * 0.46f, rx * 0.08f, spotPaint)
        canvas.drawCircle(cx + rx * 0.62f, cy + ry * 0.10f, rx * 0.07f, spotPaint)

        // Eye bumps.
        val eyeRy = rx * 0.24f * (if (now < blinkUntil && !ambient) 0.12f else 1f)
        val eyeCy = cy - ry * 0.82f
        for (side in intArrayOf(-1, 1)) {
            val ex = cx + side * rx * 0.44f
            val eye = RectF(ex - rx * 0.24f, eyeCy - eyeRy, ex + rx * 0.24f, eyeCy + eyeRy)
            canvas.drawOval(eye, bodyPaint)
            canvas.drawOval(eye, inkPaint)
            if (now >= blinkUntil || ambient) {
                fillPaint.color = 0xFF2B2B20.toInt()
                canvas.drawCircle(ex, eyeCy, rx * 0.09f, fillPaint)
            }
        }

        // Smile.
        inkPaint.style = Paint.Style.STROKE
        val mouth = RectF(cx - rx * 0.34f, cy + ry * 0.02f, cx + rx * 0.34f, cy + ry * 0.52f)
        canvas.drawArc(mouth, 25f, 130f, false, inkPaint)

        // Coral cheeks.
        if (!ambient) {
            canvas.drawCircle(cx - rx * 0.58f, cy + ry * 0.16f, rx * 0.11f, cheekPaint)
            canvas.drawCircle(cx + rx * 0.58f, cy + ry * 0.16f, rx * 0.11f, cheekPaint)
        }
    }
}
