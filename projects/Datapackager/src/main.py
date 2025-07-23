import argparse
import pickle

class DataContainer:
    def __init__(self, data, metadata):
        self.data = data
        self.metadata = metadata

class Packager:
    def __init__(self):
        self.container = None

    def package(self, data_file, metadata):
        with open(data_file, "rb") as f:
            file_content = f.read()
        self.container = DataContainer(file_content, metadata)

    def export(self, output_file):
        with open(output_file, "wb") as f:
            pickle.dump(self.container, f)

    def import_package(self, package_file):
        with open(package_file, "rb") as f:
            self.container = pickle.load(f)

    def extract(self, output_file):
        if not self.container:
            print("No data loaded.")
            return
        with open(output_file, "wb") as f:
            f.write(self.container.data)
        print(f"Data extracted to {output_file}.")

def main():
    parser = argparse.ArgumentParser(description="Package files with metadata for transfer.")
    subparsers = parser.add_subparsers(dest="command")

    pack_parser = subparsers.add_parser("package", help="Package a file with metadata")
    pack_parser.add_argument("file", help="File to package")
    pack_parser.add_argument("--meta", required=True, help="Metadata string to include")
    pack_parser.add_argument("-o", "--output", required=True, help="Output package file")

    unpack_parser = subparsers.add_parser("unpack", help="Unpack a package file")
    unpack_parser.add_argument("package", help="Input package file")
    unpack_parser.add_argument("--extract", help="File to extract data to")

    args = parser.parse_args()
    p = Packager()

    if args.command == "package":
        p.package(args.file, args.meta)
        p.export(args.output)
        print(f"Packaged {args.file} to {args.output}")
    elif args.command == "unpack":
        p.import_package(args.package)
        if args.extract:
            p.extract(args.extract)
        else:
            print(f"Loaded metadata: {p.container.metadata}")
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
