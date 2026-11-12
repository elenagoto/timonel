<?php
/**
 * Plugin Name: Timonel Mailpit
 * Description: Sends all WordPress mail to the shared Mailpit service (http://timonel-mailpit.localhost). Added by Timonel.
 */

// WordPress ignores SMTP_* constants on its own; route PHPMailer through
// Mailpit's SMTP server instead of the (missing) local sendmail.
add_action( 'phpmailer_init', function ( $phpmailer ) {
    $phpmailer->isSMTP();
    $phpmailer->Host        = defined( 'SMTP_HOST' ) ? SMTP_HOST : 'mailpit';
    $phpmailer->Port        = defined( 'SMTP_PORT' ) ? SMTP_PORT : 1025;
    $phpmailer->SMTPAuth    = false;
    $phpmailer->SMTPAutoTLS = false;
} );
