import os
import subprocess

BATCH_FOLDER = "batch_files"

def list_batch_files():
    """List all .sh files in the batch_files directory."""
    if not os.path.isdir(BATCH_FOLDER):
        print(f"Error: '{BATCH_FOLDER}' folder not found.")
        exit(1)

    files = [f for f in os.listdir(BATCH_FOLDER) if f.endswith('.sh')]
    files.sort()  # Optional: Sort files like 01_, 02_, etc.
    return files

def make_executable(filepath):
    """Ensure the file is executable."""
    subprocess.run(["chmod", "+x", filepath], check=True)

def print_instructions():
    """Print basic usage instructions."""
    print("Instructions:")
    print(f"1. Place all your batch scripts inside the '{BATCH_FOLDER}' folder.")
    print(f"2. Ensure they are named like '01_task.sh', '02_task.sh', etc.")
    print("3. The script will automatically chmod +x before running.\n")

def menu(batch_files):
    """Show the menu and allow user to pick a batch file to run."""
    while True:
        print("\nAvailable Batch Scripts:")
        for idx, file in enumerate(batch_files, start=1):
            print(f"{idx}. {file}")
        print(f"{len(batch_files)+1}. Exit")
        
        try:
            choice = int(input("\nEnter your choice: "))
            if choice == len(batch_files) + 1:
                print("Exiting...")
                break
            elif 1 <= choice <= len(batch_files):
                script_path = os.path.join(BATCH_FOLDER, batch_files[choice-1])
                make_executable(script_path)
                print(f"Running '{batch_files[choice-1]}'...\n")
                subprocess.run([script_path], check=True)
            else:
                print("Invalid choice. Please try again.")
        except (ValueError, IndexError):
            print("Please enter a valid number.")
        except subprocess.CalledProcessError:
            print("Error running the script. Please check your batch file.")

def main():
    print_instructions()
    batch_files = list_batch_files()
    if not batch_files:
        print(f"No batch files found in '{BATCH_FOLDER}'.")
        exit(0)
    menu(batch_files)

if __name__ == "__main__":
    main()

"""
chmod +x batch_files/*.sh
chmod +x 01_do_this.sh      02_do_that.sh       03_another_task.sh



"""