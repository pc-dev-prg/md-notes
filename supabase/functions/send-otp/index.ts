const { createClient } = require('@supabase/supabase-js');

module.exports = async function (req, res) {
  if (req.method === 'OPTIONS') {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Headers', 'authorization, x-client-info, apikey, content-type');
    res.status(200).send();
    return;
  }

  try {
    const supabaseUrl = process.env.SUPABASE_URL || '';
    const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || '';
    const supabase = createClient(supabaseUrl, supabaseKey);

    const { email, otp } = req.body;

    if (!email || !otp) {
      throw new Error('Email and OTP are required.');
    }

    // Send the OTP via email
    const { error } = await supabase.auth.signInWithOtp({
      email: email,
      options: {
        emailRedirectTo: `${supabaseUrl}/dashboard`,
      },
    });

    if (error) {
      console.error('Error sending OTP:', error);
      throw new Error('Failed to send OTP.');
    }

    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Content-Type', 'application/json');
    res.status(200).send(JSON.stringify({ message: 'OTP sent successfully!' }));
  } catch (error) {
    console.error('Error:', error);
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Content-Type', 'application/json');
    res.status(400).send(JSON.stringify({ error: error.message }));
  }
};
