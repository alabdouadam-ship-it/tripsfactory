const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://jkeimaazqmsataoeigsf.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImprZWltYWF6cW1zYXRhb2VpZ3NmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk3MDcwMjksImV4cCI6MjA4NTI4MzAyOX0.qJlYekLc8Ja3i6eW0HQpMd0mKU6CxaVQMJ431ONo7pc';

const supabase = createClient(supabaseUrl, supabaseKey);

async function testLogin() {
    console.log("Enter email that failed login:");
    const readline = require('readline').createInterface({
        input: process.stdin,
        output: process.stdout
    });

    readline.question('Email: ', async (email) => {
        readline.question('Password: ', async (password) => {
            console.log("\nSigning in...");
            const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
                email,
                password,
            });

            if (authError) {
                console.error("Auth error:", authError.message);
                process.exit(1);
            }

            console.log("Logged in UID:", authData.user.id);

            console.log("Checking profile for is_admin...");
            const { data: profile, error: profileError } = await supabase
                .from('profiles')
                .select('is_admin')
                .eq('id', authData.user.id)
                .single();

            if (profileError) {
                console.error("Profile error:", profileError.message);
                process.exit(1);
            }

            console.log("Profile is_admin:", profile?.is_admin);
            process.exit(0);
        });
    });
}

testLogin();
