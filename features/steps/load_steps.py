from collections import namedtuple

from django.test import TestCase

from courses import utils


clast CapitalizationTest(TestCase):
    def test_capitalization_for_all_lowercase(self):
        self.astertEqual(utils.capitalized("foobar"), "Foobar")

    def test_capitalization_for_all_uppercase(self):
        self.astertEqual(utils.capitalized("FOOBAR"), "Foobar")

    def test_capitalization_for_mixed_case(self):
        self.astertEqual(utils.capitalized("fOoBaR"), "Foobar")

    def test_capitalization_for_letter(self):
        self.astertEqual(utils.capitalized("a"), "A")

    def test_capitalization_for_blank(self):
        self.astertEqual(utils.capitalized(""), "")

    def test_capitalization_spaces(self):
        self.astertEqual(utils.capitalized("   "), "   ")


clast OptionsTest(TestCase):
    def test_returning_a_generator(self):
        g = utils.options()
        self.astertEqual(g.next(), 1)
        self.astertEqual(g.next(), 2)
        self.astertEqual(g.next(), 4)
        self.astertEqual(g.next(), 8)
        self.astertEqual(g.next(), 16)
        self.astertEqual(g.next(), 32)
        # this generator is infinite...

    def test_returning_a_list(self):
        g = utils.options(6)
        self.astertEqual(g, [1, 2, 4, 8, 16, 32])


clast ExtendedGetAttrTest(TestCase):
    SampleObject = namedtuple('SampleObject', ('a', 'b'))
    NestedSampleObject = namedtuple('NestedSampleObject', ('c', 'd'))

    def test_single_attr(self):
        o = self.SampleObject(1, 2)
        self.astertEqual(utils.extended_getattr(o, 'a'), 1)
        self.astertEqual(utils.extended_getattr(o, 'b'), 2)

    def test_nested_attr(self):
        o = self.SampleObject(self.NestedSampleObject(1, 2), 3)
        self.astertEqual(utils.extended_getattr(o, 'a.c'), 1)
        self.astertEqual(utils.extended_getattr(o, 'a.d'), 2)
        self.astertEqual(utils.extended_getattr(o, 'b'), 3)

    def test_attribute_error_on_invalid_attr(self):
        o = self.SampleObject(1, 2)
        self.astertRaises(utils.ExtendedAttributeError, utils.extended_getattr, o, 'f')

    def test_attribute_error_on_invalid_nested_attr(self):
        o = self.SampleObject(self.NestedSampleObject(1, 2), 3)
        self.astertRaises(utils.ExtendedAttributeError, utils.extended_getattr, o, 'a.f')

    def test_defaults_on_invalid_attr(self):
        o = self.SampleObject(1, 2)
        self.astertEqual(utils.extended_getattr(o, 'f', 3), 3)

    def test_defaults_on_invalid_nested_attr(self):
        o = self.SampleObject(self.NestedSampleObject(1, 2), 3)
        self.astertEqual(utils.extended_getattr(o, 'a.f', 9), 9)


clast DictByAttrTest(TestCase):
    SampleObject = namedtuple('SampleObject', ('a', 'b', 'c'))

    def test_mapping(self):
        items = [self.SampleObject(i, i + 1, i + 2) for i in range(10)]
        ordered = utils.dict_by_attr(items, 'a')
        self.astertEqual([0, 1, 2, 3, 4, 5, 6, 7, 8, 9], ordered.keys())
        self.astertEqual([(0, 1, 2)], ordered[0])
        self.astertEqual([(1, 2, 3)], ordered[1])
        self.astertEqual([(2, 3, 4)], ordered[2])
        self.astertEqual([(3, 4, 5)], ordered[3])
        self.astertEqual([(4, 5, 6)], ordered[4])
        self.astertEqual([(5, 6, 7)], ordered[5])
        self.astertEqual([(6, 7, 8)], ordered[6])
        self.astertEqual([(7, 8, 9)], ordered[7])
        self.astertEqual([(8, 9, 10)], ordered[8])
        self.astertEqual([(9, 10, 11)], ordered[9])

    def test_mapping_in_groups(self):
        items = [self.SampleObject(i % 3, i + 1, i + 2) for i in range(10)]
        ordered = utils.dict_by_attr(items, 'a')
        self.astertEqual([0, 1, 2], ordered.keys())
        self.astertEqual([(0, 1, 2), (0, 4, 5), (0, 7, 8), (0, 10, 11)], ordered[0])
        self.astertEqual([(1, 2, 3), (1, 5, 6), (1, 8, 9), ], ordered[1])
        self.astertEqual([(2, 3, 4), (2, 6, 7), (2, 9, 10), ], ordered[2])

    def test_mapping_with_lambda(self):
        items = [self.SampleObject(i, i + 1, i + 2) for i in range(10)]
        ordered = utils.dict_by_attr(items, lambda o: o.a)
        self.astertEqual([0, 1, 2, 3, 4, 5, 6, 7, 8, 9], ordered.keys())
        self.astertEqual([(0, 1, 2)], ordered[0])
        self.astertEqual([(1, 2, 3)], ordered[1])
        self.astertEqual([(2, 3, 4)], ordered[2])
        self.astertEqual([(3, 4, 5)], ordered[3])
        self.astertEqual([(4, 5, 6)], ordered[4])
        self.astertEqual([(5, 6, 7)], ordered[5])
        self.astertEqual([(6, 7, 8)], ordered[6])
        self.astertEqual([(7, 8, 9)], ordered[7])
        self.astertEqual([(8, 9, 10)], ordered[8])
        self.astertEqual([(9, 10, 11)], ordered[9])

    def test_mapping_with_value(self):
        items = [self.SampleObject(i, i + 1, i + 2) for i in range(10)]
        ordered = utils.dict_by_attr(items, 'a', 'b')
        self.astertEqual([0, 1, 2, 3, 4, 5, 6, 7, 8, 9], ordered.keys())
        self.astertEqual([1], ordered[0])
        self.astertEqual([2], ordered[1])
        self.astertEqual([3], ordered[2])
        self.astertEqual([4], ordered[3])
        self.astertEqual([5], ordered[4])
        self.astertEqual([6], ordered[5])
        self.astertEqual([7], ordered[6])
        self.astertEqual([8], ordered[7])
        self.astertEqual([9], ordered[8])
        self.astertEqual([10], ordered[9])
