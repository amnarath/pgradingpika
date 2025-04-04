import { createClient } from 'npm:@supabase/supabase-js@2.39.7';
import { Resend } from 'npm:resend@2.1.0';

const resend = new Resend(Deno.env.get('RESEND_API_KEY'));
const supabaseUrl = Deno.env.get('SUPABASE_URL');
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

const supabase = createClient(supabaseUrl!, supabaseServiceKey!);

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface EmailPayload {
  userId: string;
  entryId: string;
  amount: number;
  surchargeAmount?: number;
  bankDetails: {
    iban: string;
    bic: string;
    recipient: string;
    reference: string;
  };
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { userId, entryId, amount, surchargeAmount, bankDetails } = await req.json() as EmailPayload;

    // Get user email - explicitly specify the table
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('users.email')
      .eq('users.id', userId)
      .single();

    if (userError || !user) {
      throw new Error('User not found');
    }

    const totalAmount = surchargeAmount ? amount + surchargeAmount : amount;

    const { data: emailResponse, error: emailError } = await resend.emails.send({
      from: 'Pikamon Grading <grading@pikamon.eu>',
      to: user.email,
      subject: surchargeAmount ? 'Surcharge Payment Required - Pikamon Grading' : 'Payment Required - Pikamon Grading',
      html: `
        <h1>Payment Required for Your Grading Submission</h1>
        <p>Thank you for your grading submission. Please complete the payment using the following details:</p>
        
        <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
          <h2>Payment Details</h2>
          <p><strong>Amount Due:</strong> €${totalAmount.toFixed(2)}</p>
          ${surchargeAmount ? `<p><small>(Includes surcharge of €${surchargeAmount.toFixed(2)})</small></p>` : ''}
          <p><strong>IBAN:</strong> ${bankDetails.iban}</p>
          <p><strong>BIC:</strong> ${bankDetails.bic}</p>
          <p><strong>Recipient:</strong> ${bankDetails.recipient}</p>
          <p><strong>Reference:</strong> ${bankDetails.reference}</p>
        </div>

        <p><strong>Important:</strong> Please include the reference number in your transfer to ensure proper processing.</p>
        
        <p>If you have any questions, please don't hesitate to contact us.</p>
      `
    });

    if (emailError) {
      throw emailError;
    }

    return new Response(
      JSON.stringify({ message: 'Email sent successfully' }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    );

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      },
    );
  }
});