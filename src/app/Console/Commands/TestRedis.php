<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Jobs\ProcessPodcast;
use App\Models\Podcast;

class TestRedis extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'app:test-redis';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Command description';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $this->info('Test started' . ' at ' . date('Y-m-d H:i:s'));

        for ($i = 0; $i < 50000; $i++) {
            $podcast = new Podcast();
            $podcast->id = $i;
            
            ProcessPodcast::dispatch($podcast);
            if ($i % 1000 === 0)
            $this->info('Jobs queued: ' . $i . ' at ' . date('Y-m-d H:i:s'));            
        }
      
        $this->info('Test concluded' . ' at ' . date('Y-m-d H:i:s'));

    }
}
