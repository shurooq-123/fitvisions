package com.example.fitvisions

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.widget.Toast

private val recoveryHosts = setOf(
    "fitvisions-33e6d.firebaseapp.com",
    "fitvisions-33e6d.web.app"
)

private fun Uri.isFitVisionsLink(): Boolean =
    isHierarchical && scheme == "https" && host in recoveryHosts &&
        port == -1 && userInfo == null

internal fun passwordResetCode(link: Uri): String? {
    if (!link.isFitVisionsLink()) return null
    val action = if (link.path == "/__/auth/links") {
        val nested = link.getQueryParameter("link") ?: link.getQueryParameter("deep_link_id")
        if (nested.isNullOrBlank()) return null
        Uri.parse(nested)
    } else {
        link
    }
    if (!action.isFitVisionsLink() ||
        action.path !in setOf("/__/auth/action", "/reset-password")
    ) return null
    val parameters = if (action.path == "/reset-password" && !action.encodedFragment.isNullOrBlank()) {
        Uri.Builder().encodedQuery(action.encodedFragment).build()
    } else {
        action
    }
    if (parameters.getQueryParameter("mode") != "resetPassword") return null
    return parameters.getQueryParameter("oobCode")?.takeIf { it.isNotBlank() && it.length <= 2048 }
}

internal fun passwordResetPage(code: String): Uri =
    Uri.Builder()
        .scheme("https")
        .authority("fitvisions-33e6d.firebaseapp.com")
        .path("/reset-password")
        .appendQueryParameter("v", "2")
        .encodedFragment("mode=resetPassword&oobCode=${Uri.encode(code)}")
        .build()

/** Opens the emailed Firebase action in the browser without showing an app screen. */
class PasswordResetLinkActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            val link = intent.data ?: return
            if (intent.action != Intent.ACTION_VIEW || !link.isFitVisionsLink()) return

            val code = passwordResetCode(link)
            val destination = if (code != null) {
                passwordResetPage(code)
            } else if (link.path == "/__/auth/action" &&
                link.getQueryParameter("mode") != "resetPassword") {
                // Other email actions continue through Firebase's browser handler.
                link.buildUpon().encodedPath("/reset-password").build()
            } else {
                Toast.makeText(this, "Request a new FitVisions password reset link.", Toast.LENGTH_LONG).show()
                return
            }
            startActivity(Intent(Intent.ACTION_VIEW, destination))
        } catch (_: ActivityNotFoundException) {
            Toast.makeText(this, "Open the email link in a web browser.", Toast.LENGTH_LONG).show()
        } finally {
            finish()
        }
    }
}
