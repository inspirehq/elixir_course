# Day 1 – FLAME: Comprehensive Primer for Elixir
#
# This script can be run with:
#     mix run day_one/16_flame_comprehensive_primer.exs
# or inside IEx with:
#     iex -r day_one/16_flame_comprehensive_primer.exs
#
# FLAME (Fleeting Lambda Application for Modular Execution) is a revolutionary
# library that lets you execute any block of code on short-lived infrastructure
# that automatically scales up and down based on demand.
#
# This file covers:
#   • Understanding FLAME's "entire application as lambda" concept
#   • Basic FLAME.call/2 and FLAME.cast/2 operations
#   • FLAME.Pool configuration and backends
#   • Real-world use cases: file processing, ML inference, background jobs
#   • Advanced patterns: code synchronization, resource tracking
#   • Performance considerations and best practices
# ────────────────────────────────────────────────────────────────

IO.puts("\n🔥 FLAME Comprehensive Primer")
IO.puts("=" |> String.duplicate(50))

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 1 – Understanding FLAME vs Traditional Approaches")
# =====================================================================
# 🚀  THE FLAME PARADIGM SHIFT
# ---------------------------------------------------------------------
#  Traditional serverless: Write small, isolated functions that run in
#  constrained environments with cold start penalties and complex state
#  management.
#
#  FLAME approach: Your ENTIRE application becomes the "lambda". Any
#  block of code can be executed on short-lived infrastructure with
#  full access to your app's context, database connections, and state.
#
# WHY THIS MATTERS
#   • No cold starts - your full app boots once
#   • No context switching - same codebase, same APIs
#   • No state synchronization - it's your app with your database
#   • Auto-scaling without complexity - FLAME handles infrastructure
#
# WHAT WE DEMO HERE
#   Compare a traditional approach vs FLAME for file processing
# =====================================================================

# Simulate traditional approach - limited context, complex setup
defmodule TraditionalFileProcessor do
  def process_file(file_path) do
    # In traditional serverless, you'd need to:
    # 1. Download file from storage
    # 2. Process with limited memory/CPU
    # 3. Upload results back to storage
    # 4. Send notifications via API calls
    # 5. Update database via HTTP API

    IO.puts("🐌 Traditional: Multiple API calls, cold starts, context switching")
    {:ok, "processed_via_traditional_serverless"}
  end
end

# FLAME approach - full application context
defmodule FlameFileProcessor do
  def process_file(file_path) do
    # With FLAME, you have access to:
    # - Your full application
    # - Database connections (Repo)
    # - Phoenix PubSub
    # - All your existing modules and functions
    # - Full memory and CPU of the spawned machine

    IO.puts("🔥 FLAME: Full app context, database access, pubsub, existing APIs")

    # Simulate file processing with full app access
    result = "processed_#{Path.basename(file_path)}"

    # Could directly use your app's context:
    # - MyApp.Repo.insert!(result)
    # - Phoenix.PubSub.broadcast(MyApp.PubSub, "updates", {:file_done, result})
    # - MyApp.Email.send_completion_email(user)

    {:ok, result}
  end
end

# Demo the difference (this would normally use FLAME.call/2)
TraditionalFileProcessor.process_file("/tmp/large_video.mp4")
FlameFileProcessor.process_file("/tmp/large_video.mp4")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – FLAME.Pool Configuration and Backends")
# =====================================================================
# 🎛️  FLAME POOL SETUP
# ---------------------------------------------------------------------
#  FLAME.Pool is the GenServer that manages your fleet of runner nodes.
#  It handles elastic scaling, load balancing, and resource management.
#
# KEY CONFIGURATION OPTIONS
#   • :min - Minimum runners (0 for scale-to-zero)
#   • :max - Maximum runners for cost control
#   • :max_concurrency - Tasks per runner before spawning new ones
#   • :idle_shutdown_after - How long to keep idle runners
#   • :backend - Where to run (Fly, K8s, Local)
#
# BACKENDS AVAILABLE
#   • FLAME.FlyBackend - Fly.io machines (production ready)
#   • FLAME.K8sBackend - Kubernetes pods
#   • FLAME.LocalBackend - Local processes (development/testing)
# =====================================================================

# Example application supervision tree setup
defmodule MyApp.Application do
  def start_flame_pools do
    children = [
      # CPU-intensive tasks pool
      {FLAME.Pool,
       name: MyApp.CpuRunner,
       min: 0,                          # Scale to zero when idle
       max: 5,                          # Max 5 machines
       max_concurrency: 2,              # 2 tasks per machine
       idle_shutdown_after: 30_000,     # Shutdown after 30s idle
       backend: FLAME.FlyBackend},      # Use Fly.io backend

      # Memory-intensive tasks pool
      {FLAME.Pool,
       name: MyApp.MemoryRunner,
       min: 1,                          # Keep 1 warm
       max: 3,                          # Max 3 machines
       max_concurrency: 1,              # 1 task per machine
       idle_shutdown_after: 300_000,    # Keep warm for 5 minutes
       backend: {FLAME.FlyBackend,      # Custom Fly configuration
                 cpu_kind: "performance",
                 cpus: 4,
                 memory_mb: 8192}},

      # Development/testing pool
      {FLAME.Pool,
       name: MyApp.LocalRunner,
       min: 0,
       max: 2,
       max_concurrency: 10,
       backend: FLAME.LocalBackend}     # Local processes only
    ]
  end
end

IO.puts("✅ Pool configurations defined for different workload types")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Basic FLAME Operations: call vs cast")
# =====================================================================
# 🎯  FLAME.call vs FLAME.cast
# ---------------------------------------------------------------------
#  FLAME provides two main operations for running code on remote runners:
#
#  • FLAME.call/2 - Synchronous, waits for result, like Task.async/await
#  • FLAME.cast/2 - Fire-and-forget, doesn't wait for result
#
# WHEN TO USE EACH
#   call: When you need the result (image processing, calculations)
#   cast: Background tasks, logging, notifications, cleanup
# =====================================================================

# Simulate FLAME operations (these would normally connect to actual runners)
defmodule FlameOperationsDemo do
  # Simulate FLAME.call - synchronous operation
  def demo_call do
    IO.puts("🔄 FLAME.call - Synchronous operation")

    # This would normally be:
    # result = FLAME.call(MyApp.CpuRunner, fn ->
    #   # Expensive computation happens on remote machine
    #   :math.pow(2, 20) |> trunc()
    # end)

    # Simulated for demo
    result = 1_048_576
    IO.puts("   ✅ Got result: #{result}")
    result
  end

  # Simulate FLAME.cast - asynchronous operation
  def demo_cast do
    IO.puts("🚀 FLAME.cast - Fire-and-forget operation")

    # This would normally be:
    # FLAME.cast(MyApp.CpuRunner, fn ->
    #   # Background cleanup happens on remote machine
    #   File.rm_rf!("/tmp/old_files")
    #   MyApp.Metrics.increment("cleanup_completed")
    # end)

    # Simulated for demo
    IO.puts("   ✅ Cleanup task sent to runner (no waiting)")
    :ok
  end

  # Real-world example: Image processing pipeline
  def process_image(image_path) do
    IO.puts("🖼️  Processing image: #{Path.basename(image_path)}")

    # This would be a real FLAME.call
    # thumbnail = FLAME.call(MyApp.ImageRunner, fn ->
    #   # ImageMagick operations on high-memory machine
    #   Mogrify.open(image_path)
    #   |> Mogrify.resize("300x300")
    #   |> Mogrify.save(path: "/tmp/thumbnail.jpg")
    #   |> Mogrify.path
    # end)

    thumbnail = "/tmp/thumbnail_#{Path.basename(image_path)}"
    IO.puts("   ✅ Thumbnail created: #{Path.basename(thumbnail)}")

    # Fire-and-forget notification
    # FLAME.cast(MyApp.NotificationRunner, fn ->
    #   MyApp.Email.send_processing_complete(user_id, thumbnail)
    #   Phoenix.PubSub.broadcast(MyApp.PubSub, "images", {:processed, image_path})
    # end)

    IO.puts("   ✅ Notification sent via cast")
    {:ok, thumbnail}
  end
end

# Demo the operations
FlameOperationsDemo.demo_call()
FlameOperationsDemo.demo_cast()
FlameOperationsDemo.process_image("/uploads/vacation_photo.jpg")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Real-world Use Case: Video Processing Pipeline")
# =====================================================================
# 🎬  VIDEO PROCESSING WITH FLAME
# ---------------------------------------------------------------------
#  Common use case: User uploads video, needs thumbnail generation,
#  transcoding, and metadata extraction. Perfect for FLAME because:
#
#  • CPU/Memory intensive (needs beefy machines)
#  • Sporadic demand (don't want to pay for idle capacity)
#  • Multiple steps (thumbnails, transcoding, cleanup)
#  • Needs app context (database, storage, notifications)
# =====================================================================

defmodule VideoProcessingPipeline do
  # Main entry point - called from web request
  def process_upload(video_path, user_id) do
    IO.puts("🎬 Starting video processing pipeline")
    IO.puts("   📁 Video: #{Path.basename(video_path)}")
    IO.puts("   👤 User: #{user_id}")

    # Step 1: Quick metadata extraction (synchronous)
    metadata = extract_metadata(video_path)

    # Step 2: Thumbnail generation (synchronous - user sees it immediately)
    thumbnail = generate_thumbnail(video_path)

    # Step 3: Background transcoding (asynchronous - takes time)
    start_background_transcoding(video_path, user_id, metadata)

    {:ok, %{metadata: metadata, thumbnail: thumbnail}}
  end

  defp extract_metadata(video_path) do
    IO.puts("🔍 Extracting metadata...")

    # Real FLAME.call would be:
    # FLAME.call(MyApp.VideoRunner, fn ->
    #   {output, 0} = System.cmd("ffprobe", [
    #     "-v", "quiet",
    #     "-print_format", "json",
    #     "-show_format",
    #     video_path
    #   ])
    #   Jason.decode!(output)
    # end)

    # Simulated metadata
    metadata = %{
      duration: "00:05:30",
      format: "mp4",
      resolution: "1920x1080",
      file_size: "50MB"
    }

    IO.puts("   ✅ Metadata extracted: #{metadata.duration}")
    metadata
  end

  defp generate_thumbnail(video_path) do
    IO.puts("🖼️  Generating thumbnail...")

    # Real FLAME.call would be:
    # FLAME.call(MyApp.VideoRunner, fn ->
    #   tmp_dir = System.tmp_dir!()
    #   thumbnail_path = Path.join(tmp_dir, "thumb_#{:rand.uniform(1000)}.jpg")
    #
    #   {_output, 0} = System.cmd("ffmpeg", [
    #     "-i", video_path,
    #     "-vf", "thumbnail,scale=320:240",
    #     "-frames:v", "1",
    #     thumbnail_path
    #   ])
    #
    #   # Upload to S3/storage and return URL
    #   upload_to_storage(thumbnail_path)
    # end)

    thumbnail_url = "https://storage.app/thumbnails/thumb_#{:rand.uniform(1000)}.jpg"
    IO.puts("   ✅ Thumbnail generated: #{thumbnail_url}")
    thumbnail_url
  end

  defp start_background_transcoding(video_path, user_id, metadata) do
    IO.puts("🚀 Starting background transcoding...")

    # Real FLAME.cast would be:
    # FLAME.cast(MyApp.VideoRunner, fn ->
    #   # Multiple transcoding formats
    #   formats = ["720p", "480p", "360p"]
    #
    #   transcoded_urls = Enum.map(formats, fn format ->
    #     transcode_to_format(video_path, format)
    #   end)
    #
    #   # Update database with results
    #   MyApp.Repo.update_video_processing_status(video_path, :completed, transcoded_urls)
    #
    #   # Notify user
    #   Phoenix.PubSub.broadcast(MyApp.PubSub, "user:#{user_id}",
    #     {:video_ready, video_path, transcoded_urls})
    #
    #   # Cleanup original file
    #   File.rm(video_path)
    # end)

    IO.puts("   ✅ Background transcoding started")
    :ok
  end
end

# Demo the video pipeline
VideoProcessingPipeline.process_upload("/uploads/user_video.mp4", 123)

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 5 – Machine Learning Inference at Scale")
# =====================================================================
# 🤖  ML INFERENCE WITH FLAME
# ---------------------------------------------------------------------
#  Perfect use case for FLAME: ML models that need GPU/high-memory
#  machines but have sporadic usage patterns.
#
#  • Models can be expensive to keep loaded
#  • GPU instances cost $$$ when idle
#  • Need to scale from 0 to many based on demand
#  • Want to batch process when possible
# =====================================================================

defmodule MLInferencePipeline do
  # Real-time inference for user request
  def classify_image(image_path, user_id) do
    IO.puts("🤖 Running ML classification...")
    IO.puts("   🖼️  Image: #{Path.basename(image_path)}")

    # Real FLAME.call with GPU backend:
    # result = FLAME.call(MyApp.GPURunner, fn ->
    #   # Load model if not cached
    #   model = load_or_get_cached_model()
    #
    #   # Preprocess image
    #   tensor = image_path
    #   |> Nx.load_image!()
    #   |> Nx.resize({224, 224})
    #   |> Nx.normalize()
    #
    #   # Run inference
    #   prediction = Axon.predict(model, %{"input" => tensor})
    #
    #   # Postprocess results
    #   %{
    #     class: extract_top_class(prediction),
    #     confidence: extract_confidence(prediction),
    #     processed_at: DateTime.utc_now()
    #   }
    # end)

    # Simulated result
    result = %{
      class: "golden_retriever",
      confidence: 0.94,
      processed_at: DateTime.utc_now()
    }

    IO.puts("   ✅ Classification: #{result.class} (#{result.confidence * 100}%)")
    {:ok, result}
  end

  # Batch processing for efficiency
  def batch_classify_images(image_paths) do
    IO.puts("🤖 Running batch ML classification...")
    IO.puts("   📊 Batch size: #{length(image_paths)}")

    # Real FLAME.call with batch processing:
    # results = FLAME.call(MyApp.GPURunner, fn ->
    #   model = load_or_get_cached_model()
    #
    #   # Process images in batches for GPU efficiency
    #   batch_size = 32
    #
    #   image_paths
    #   |> Enum.chunk_every(batch_size)
    #   |> Enum.flat_map(fn batch ->
    #     # Batch preprocessing
    #     tensors = Enum.map(batch, &preprocess_image/1)
    #     batched_tensor = Nx.stack(tensors)
    #
    #     # Batch inference (much more efficient on GPU)
    #     predictions = Axon.predict(model, %{"input" => batched_tensor})
    #
    #     # Return results for each image
    #     Enum.zip(batch, predictions)
    #     |> Enum.map(fn {path, pred} ->
    #       {path, postprocess_prediction(pred)}
    #     end)
    #   end)
    # end)

    # Simulated batch results
    results = Enum.map(image_paths, fn path ->
      {path, %{
        class: Enum.random(["cat", "dog", "bird", "car"]),
        confidence: :rand.uniform() * 0.4 + 0.6
      }}
    end)

    IO.puts("   ✅ Batch processing complete: #{length(results)} images")
    results
  end

  # Scheduled ML job (runs via Oban + FLAME)
  def daily_model_retraining do
    IO.puts("🤖 Starting daily model retraining...")

    # Real FLAME.call with high-memory instance:
    # FLAME.call(MyApp.TrainingRunner, fn ->
    #   # Fetch training data
    #   data = MyApp.TrainingData.get_recent_data()
    #
    #   # Load base model
    #   model = load_base_model()
    #
    #   # Fine-tune on recent data
    #   updated_model = train_model(model, data, epochs: 5)
    #
    #   # Save updated model
    #   save_model_to_storage(updated_model)
    #
    #   # Update model version in database
    #   MyApp.Repo.update_model_version(updated_model.version)
    #
    #   # Notify deployment system
    #   Phoenix.PubSub.broadcast(MyApp.PubSub, "ml_updates",
    #     {:model_updated, updated_model.version})
    # end, timeout: :timer.hours(2)) # Long timeout for training

    IO.puts("   ✅ Model retraining completed")
    :ok
  end
end

# Demo ML operations
MLInferencePipeline.classify_image("/uploads/dog_photo.jpg", 456)
MLInferencePipeline.batch_classify_images([
  "/uploads/cat1.jpg",
  "/uploads/dog2.jpg",
  "/uploads/bird3.jpg"
])
MLInferencePipeline.daily_model_retraining()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 6 – Data Processing and ETL Pipelines")
# =====================================================================
# 📊  DATA PROCESSING WITH FLAME
# ---------------------------------------------------------------------
#  Another excellent FLAME use case: ETL jobs that need significant
#  compute resources but run infrequently.
#
#  • Large CSV/JSON file processing
#  • Data transformation and aggregation
#  • Report generation
#  • Database migrations and cleanups
# =====================================================================

defmodule DataProcessingPipeline do
  # Process large CSV uploads
  def process_csv_upload(file_path, user_id) do
    IO.puts("📊 Processing large CSV file...")
    IO.puts("   📁 File: #{Path.basename(file_path)}")

    # Real FLAME.call for CPU-intensive processing:
    # result = FLAME.call(MyApp.DataRunner, fn ->
    #   file_path
    #   |> File.stream!()
    #   |> CSV.decode!(headers: true)
    #   |> Stream.chunk_every(1000) # Process in chunks
    #   |> Stream.map(&process_chunk/1)
    #   |> Stream.map(&validate_chunk/1)
    #   |> Stream.map(&transform_chunk/1)
    #   |> Enum.reduce(%{processed: 0, errors: []}, &accumulate_results/2)
    # end)

    # Simulated processing result
    result = %{
      processed: 50_000,
      errors: ["Row 1,234: Invalid date format", "Row 5,678: Missing required field"],
      duration_ms: 45_000
    }

    IO.puts("   ✅ Processed #{result.processed} rows in #{result.duration_ms}ms")
    IO.puts("   ⚠️  #{length(result.errors)} errors found")

    {:ok, result}
  end

  # Generate complex reports
  def generate_monthly_report(month, year) do
    IO.puts("📈 Generating monthly report: #{month}/#{year}")

    # Real FLAME.call for memory-intensive report generation:
    # report = FLAME.call(MyApp.ReportRunner, fn ->
    #   # Complex queries and aggregations
    #   sales_data = MyApp.Analytics.get_sales_data(month, year)
    #   user_metrics = MyApp.Analytics.get_user_metrics(month, year)
    #   financial_data = MyApp.Analytics.get_financial_data(month, year)
    #
    #   # Generate charts and visualizations
    #   charts = %{
    #     sales_chart: generate_sales_chart(sales_data),
    #     growth_chart: generate_growth_chart(user_metrics),
    #     revenue_chart: generate_revenue_chart(financial_data)
    #   }
    #
    #   # Generate PDF report
    #   pdf_path = generate_pdf_report(sales_data, user_metrics, financial_data, charts)
    #
    #   # Upload to S3 and return URL
    #   upload_report_to_storage(pdf_path)
    # end, timeout: :timer.minutes(10))

    # Simulated report generation
    report_url = "https://storage.app/reports/monthly_#{month}_#{year}.pdf"
    IO.puts("   ✅ Report generated: #{report_url}")

    {:ok, report_url}
  end

  # Database cleanup job
  def cleanup_old_data(cutoff_date) do
    IO.puts("🧹 Starting database cleanup...")
    IO.puts("   📅 Cutoff date: #{cutoff_date}")

    # Real FLAME.call for database-intensive operations:
    # result = FLAME.call(MyApp.DataRunner, fn ->
    #   # Run in transaction for safety
    #   MyApp.Repo.transaction(fn ->
    #     # Clean up old logs
    #     {log_count, _} = MyApp.Repo.delete_all(
    #       from l in MyApp.Log, where: l.inserted_at < ^cutoff_date
    #     )
    #
    #     # Archive old user sessions
    #     {session_count, _} = MyApp.Repo.delete_all(
    #       from s in MyApp.Session, where: s.last_seen < ^cutoff_date
    #     )
    #
    #     # Compress old analytics data
    #     compressed_count = MyApp.Analytics.compress_old_data(cutoff_date)
    #
    #     %{
    #       logs_deleted: log_count,
    #       sessions_archived: session_count,
    #       analytics_compressed: compressed_count
    #     }
    #   end)
    # end, timeout: :timer.hours(1))

    # Simulated cleanup result
    result = %{
      logs_deleted: 1_500_000,
      sessions_archived: 250_000,
      analytics_compressed: 50_000
    }

    IO.puts("   ✅ Cleanup completed:")
    IO.puts("      📝 Logs deleted: #{result.logs_deleted}")
    IO.puts("      👤 Sessions archived: #{result.sessions_archived}")
    IO.puts("      📊 Analytics compressed: #{result.analytics_compressed}")

    {:ok, result}
  end
end

# Demo data processing operations
DataProcessingPipeline.process_csv_upload("/uploads/sales_data.csv", 789)
DataProcessingPipeline.generate_monthly_report(12, 2024)
DataProcessingPipeline.cleanup_old_data(~D[2024-01-01])

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 7 – Advanced FLAME Patterns")
# =====================================================================
# 🎯  ADVANCED FLAME USAGE
# ---------------------------------------------------------------------
#  FLAME provides several advanced features for production use:
#
#  • Code synchronization between parent and runner nodes
#  • Resource tracking to prevent premature shutdowns
#  • Custom backends for different infrastructure
#  • Integration with supervision trees and error handling
# =====================================================================

defmodule AdvancedFlamePatterns do
  # Code synchronization example
  def demo_code_sync do
    IO.puts("🔄 Code synchronization patterns...")

    # Real FLAME.Pool with code sync:
    # {FLAME.Pool,
    #  name: MyApp.SyncRunner,
    #  code_sync: [
    #    start_apps: true,           # Start all parent apps on runner
    #    copy_apps: true,            # Copy app code to runner
    #    sync_beams: [              # Sync specific beam files
    #      "/app/_build/prod/lib/myapp/ebin"
    #    ],
    #    compress: true,             # Compress during transfer
    #    verbose: true               # Log sync operations
    #  ],
    #  backend: FLAME.FlyBackend}

    IO.puts("   ✅ Code sync configured for hot code updates")
  end

  # Resource tracking example
  def demo_resource_tracking do
    IO.puts("🔍 Resource tracking patterns...")

    # Real FLAME.call with resource tracking:
    # result = FLAME.call(MyApp.FileRunner, fn ->
    #   # Open a file that implements FLAME.Trackable
    #   file = File.open!("/tmp/large_file.txt", [:write])
    #
    #   # FLAME tracks this resource and won't shutdown the runner
    #   # until the file is closed, preventing data loss
    #
    #   File.write(file, "Important data...")
    #   File.close(file)  # Now runner can safely shutdown
    #
    #   "File written safely"
    # end)

    IO.puts("   ✅ Resource tracking prevents premature shutdowns")
  end

  # Error handling and supervision
  def demo_error_handling do
    IO.puts("⚠️  Error handling patterns...")

    # Proper error handling with FLAME:
    result = try do
      # FLAME.call(MyApp.RiskyRunner, fn ->
      #   # This might fail
      #   risky_operation()
      # end, timeout: 30_000)

      # Simulated success
      {:ok, "operation completed"}

    rescue
      # Handle FLAME-specific errors
      # FLAME.Error -> {:error, :flame_error}
      error -> {:error, "Generic error: #{inspect(error)}"}
    catch
      # Handle timeouts and exits
      :exit, {:timeout, _} -> {:error, :timeout}
      :exit, reason -> {:error, {:exit, reason}}
    end

    case result do
      {:ok, data} -> IO.puts("   ✅ Success: #{data}")
      {:error, reason} -> IO.puts("   ❌ Error: #{inspect(reason)}")
    end
  end

  # Custom backend example (simplified)
  def demo_custom_backend do
    IO.puts("🏗️  Custom backend patterns...")

    # Example custom backend configuration:
    # backend = {MyApp.CustomBackend,
    #   api_url: "https://my-cloud.com/api",
    #   instance_type: "compute-optimized",
    #   region: "us-west-2",
    #   auth_token: System.get_env("CLOUD_TOKEN")}
    #
    # {FLAME.Pool,
    #  name: MyApp.CustomRunner,
    #  backend: backend}

    IO.puts("   ✅ Custom backend supports any cloud provider")
  end

  # Performance monitoring
  def demo_performance_monitoring do
    IO.puts("📊 Performance monitoring patterns...")

    # Monitor FLAME operations:
    # {time_us, result} = :timer.tc(fn ->
    #   FLAME.call(MyApp.TimedRunner, fn ->
    #     expensive_operation()
    #   end)
    # end)
    #
    # MyApp.Metrics.histogram("flame.operation.duration", time_us / 1000)
    # MyApp.Metrics.increment("flame.operation.count")

    IO.puts("   ✅ Telemetry integration for observability")
  end
end

# Demo advanced patterns
AdvancedFlamePatterns.demo_code_sync()
AdvancedFlamePatterns.demo_resource_tracking()
AdvancedFlamePatterns.demo_error_handling()
AdvancedFlamePatterns.demo_custom_backend()
AdvancedFlamePatterns.demo_performance_monitoring()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 8 – FLAME vs Alternatives Comparison")
# =====================================================================
# ⚖️   FLAME VS OTHER APPROACHES
# ---------------------------------------------------------------------
#  Understanding when to use FLAME vs other background processing
#  approaches helps you pick the right tool for the job.
#
# FLAME vs TASK.ASYNC
#   Task.async: Same node, shared resources, immediate
#   FLAME: Separate node, dedicated resources, auto-scaling
#
# FLAME vs OBAN
#   Oban: Job queue, persistent, complex workflows
#   FLAME: Direct function calls, ephemeral, simple scaling
#
# FLAME vs SERVERLESS (Lambda, etc.)
#   Serverless: Cold starts, vendor lock-in, limited context
#   FLAME: Warm starts, any backend, full app context
# =====================================================================

defmodule FlameComparison do
  # Scenario 1: Quick background task
  def quick_task_comparison do
    IO.puts("🏃 Quick background task comparison:")

    # Task.async approach
    IO.puts("   Task.async: ✅ Fast, ❌ Uses web server resources")
    # task = Task.async(fn -> quick_computation() end)
    # result = Task.await(task)

    # FLAME approach
    IO.puts("   FLAME: ✅ Dedicated resources, ❌ Slight overhead")
    # result = FLAME.call(MyApp.QuickRunner, fn -> quick_computation() end)

    IO.puts("   💡 Recommendation: Use Task.async for quick tasks")
  end

  # Scenario 2: CPU-intensive processing
  def cpu_intensive_comparison do
    IO.puts("🔥 CPU-intensive task comparison:")

    # Task.async approach
    IO.puts("   Task.async: ❌ Blocks web server, ❌ Resource contention")

    # FLAME approach
    IO.puts("   FLAME: ✅ Dedicated CPU, ✅ Auto-scaling, ✅ Isolation")

    IO.puts("   💡 Recommendation: Use FLAME for CPU-intensive tasks")
  end

  # Scenario 3: Complex workflows
  def workflow_comparison do
    IO.puts("🔄 Complex workflow comparison:")

    # Oban approach
    IO.puts("   Oban: ✅ Persistent queues, ✅ Retry logic, ✅ Job scheduling")

    # FLAME approach
    IO.puts("   FLAME: ✅ Simple calls, ❌ No built-in persistence")

    IO.puts("   💡 Recommendation: Use Oban for complex workflows, FLAME for simple scaling")
  end

  # Scenario 4: Sporadic high-resource needs
  def sporadic_workload_comparison do
    IO.puts("📈 Sporadic workload comparison:")

    # Dedicated servers
    IO.puts("   Dedicated: ❌ Always paying, ❌ Manual scaling")

    # Traditional serverless
    IO.puts("   Serverless: ✅ Pay per use, ❌ Cold starts, ❌ Limited context")

    # FLAME approach
    IO.puts("   FLAME: ✅ Pay per use, ✅ Warm starts, ✅ Full context")

    IO.puts("   💡 Recommendation: Use FLAME for sporadic high-resource workloads")
  end
end

# Demo comparisons
FlameComparison.quick_task_comparison()
FlameComparison.cpu_intensive_comparison()
FlameComparison.workflow_comparison()
FlameComparison.sporadic_workload_comparison()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 9 – Production Deployment Patterns")
# =====================================================================
# 🚀  PRODUCTION FLAME DEPLOYMENT
# ---------------------------------------------------------------------
#  Key considerations for running FLAME in production:
#
#  • Environment configuration and secrets
#  • Monitoring and observability
#  • Cost optimization strategies
#  • Security and network isolation
#  • Disaster recovery and fallbacks
# =====================================================================

defmodule ProductionPatterns do
  # Environment-specific configuration
  def demo_environment_config do
    IO.puts("🌍 Environment-specific FLAME configuration:")

    IO.puts("""
    # config/runtime.exs
    config :flame, :backend, FLAME.FlyBackend

    config :flame, FLAME.FlyBackend,
      token: System.fetch_env!("FLY_API_TOKEN"),
      cpu_kind: System.get_env("FLAME_CPU_KIND", "shared"),
      memory_mb: String.to_integer(System.get_env("FLAME_MEMORY_MB", "1024")),
      region: System.get_env("FLY_REGION", "ord"),
      env: %{
        "DATABASE_URL" => System.get_env("DATABASE_URL"),
        "SECRET_KEY_BASE" => System.get_env("SECRET_KEY_BASE")
      }

    # Development override
    if config_env() == :dev do
      config :flame, :backend, FLAME.LocalBackend
    end
    """)

    IO.puts("   ✅ Environment-aware configuration")
  end

  # Cost optimization strategies
  def demo_cost_optimization do
    IO.puts("💰 Cost optimization strategies:")

    IO.puts("""
    Production pools for cost optimization:

    # Always-on for latency-sensitive tasks
    {FLAME.Pool, name: MyApp.RealtimeRunner, min: 2, max: 10}

    # Scale-to-zero for batch processing
    {FLAME.Pool, name: MyApp.BatchRunner, min: 0, max: 5,
     idle_shutdown_after: 60_000}

    # Scheduled scaling for predictable workloads
    {FLAME.Pool, name: MyApp.NightlyRunner, min: 0, max: 20,
     idle_shutdown_after: {300_000, &during_batch_window?/0}}
    """)

    IO.puts("   ✅ Different pools for different cost/performance needs")
  end

  # Monitoring and observability
  def demo_monitoring do
    IO.puts("📊 Monitoring and observability:")

    IO.puts("""
    Key metrics to monitor:

    • Pool health: runner count, queue depth, success rates
    • Performance: execution time, resource utilization
    • Costs: runner hours, scaling events, idle time
    • Errors: failed calls, timeout rates, crash frequency

    # Telemetry integration
    :telemetry.attach("flame-metrics", [:flame, :call, :start], &handle_flame_start/4)
    :telemetry.attach("flame-metrics", [:flame, :call, :stop], &handle_flame_stop/4)

    # Custom dashboards
    MyApp.Dashboard.track_flame_pool_metrics()
    """)

    IO.puts("   ✅ Comprehensive monitoring setup")
  end

  # Security considerations
  def demo_security do
    IO.puts("🔒 Security considerations:")

    IO.puts("""
    Security best practices:

    • Network isolation: Private networks between parent and runners
    • Secret management: Secure env var injection
    • Access control: IAM roles for cloud resources
    • Code verification: Checksum validation for code sync
    • Audit logging: Track all FLAME operations

    # Secure configuration
    config :flame, FLAME.FlyBackend,
      private_networking: true,
      env: %{
        "DATABASE_URL" => {:system, "DATABASE_URL"},
        "ENCRYPTION_KEY" => {:vault, "encryption_key"}
      }
    """)

    IO.puts("   ✅ Security-first configuration")
  end

  # Fallback patterns
  def demo_fallbacks do
    IO.puts("🛡️  Fallback and resilience patterns:")

    IO.puts("""
    Handling FLAME failures gracefully:

    def resilient_operation(data) do
      case FLAME.call(MyApp.PreferredRunner, fn -> process(data) end) do
        {:ok, result} ->
          {:ok, result}
        {:error, :timeout} ->
          # Fallback to smaller runner
          FLAME.call(MyApp.FallbackRunner, fn -> process_simple(data) end)
        {:error, _} ->
          # Fallback to local processing
          {:ok, process_local(data)}
      end
    end
    """)

    IO.puts("   ✅ Graceful degradation strategies")
  end
end

# Demo production patterns
ProductionPatterns.demo_environment_config()
ProductionPatterns.demo_cost_optimization()
ProductionPatterns.demo_monitoring()
ProductionPatterns.demo_security()
ProductionPatterns.demo_fallbacks()

# ────────────────────────────────────────────────────────────────
# FLAME EXERCISES SECTION
# ────────────────────────────────────────────────────────────────

defmodule DayOne.FlameExercises do
  @moduledoc """
  Exercises for learning FLAME patterns and best practices.

  Run these in IEx to practice:
  iex -r day_one/16_flame_comprehensive_primer.exs
  """

  @spec design_pool_config(atom()) :: map()
  def design_pool_config(workload_type) do
    #   Design a FLAME.Pool configuration for the given workload type.
    #   Consider: min/max runners, concurrency, timeout, backend choice
    #
    #   Workload types:
    #   :image_processing - CPU intensive, sporadic
    #   :ml_inference - GPU needed, bursty traffic
    #   :batch_reports - Memory intensive, scheduled
    #   :api_integration - Network I/O, frequent but light
    #
    #   Return a map with your recommended configuration.
    %{}  # TODO: Implement based on workload type
  end

  @spec choose_operation_type(String.t()) :: :call | :cast
  def choose_operation_type(scenario) do
    #   Choose whether to use FLAME.call or FLAME.cast for each scenario.
    #
    #   Scenarios:
    #   "User uploads image, needs thumbnail immediately"
    #   "Send welcome email after user registration"
    #   "Generate PDF report for download"
    #   "Clean up temporary files"
    #   "Process payment and return confirmation"
    #
    #   Return :call or :cast
    :call  # TODO: Analyze scenario and choose appropriate operation
  end

  @spec estimate_costs(map()) :: map()
  def estimate_costs(pool_config) do
    #   Estimate the cost implications of a FLAME pool configuration.
    #
    #   Consider:
    #   - Number of min runners always running
    #   - Expected scaling patterns
    #   - Instance types and their hourly costs
    #   - Idle shutdown timing
    #
    #   Return cost analysis with recommendations.
    %{
      min_hourly_cost: 0,
      max_hourly_cost: 0,
      recommendations: []
    }  # TODO: Implement cost estimation logic
  end
end

# ────────────────────────────────────────────────────────────────
IO.puts("\n🎯 Key Takeaways")
# ────────────────────────────────────────────────────────────────

IO.puts("""
FLAME Revolutionary Concepts:
🔥 Entire Application as Lambda - Your full app context, not isolated functions
⚡ Zero Cold Starts - Full application boots once, stays warm
🎯 Context Preservation - Database, PubSub, all your APIs available
📈 Intelligent Scaling - From 0 to many, automatically based on demand
🛠️  Any Backend - Fly, K8s, local, or custom cloud providers

When to Use FLAME:
✅ CPU/GPU intensive tasks (video, ML, data processing)
✅ Sporadic high-resource needs (reports, batch jobs)
✅ Need full app context (database, PubSub, existing APIs)
✅ Want simple auto-scaling without complexity

When NOT to Use FLAME:
❌ Quick tasks (use Task.async instead)
❌ Complex job workflows (use Oban instead)
❌ Persistent queues with retries (use Oban instead)
❌ Always-on services (use regular GenServers instead)

Production Considerations:
🔒 Security: Private networks, secret management, access control
💰 Cost: Min/max limits, idle timeouts, instance sizing
📊 Monitoring: Pool health, performance, errors, costs
🛡️  Resilience: Fallbacks, graceful degradation, error handling

FLAME represents a paradigm shift from traditional serverless to
"serverful" - where your entire application becomes the unit of scaling,
not individual functions. This eliminates context switching while
providing the benefits of elastic scaling.
""")

IO.puts("\n🔥 FLAME Primer Complete!")
IO.puts("Ready to revolutionize your scaling patterns? 🚀")
